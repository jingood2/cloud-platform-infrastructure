locals {
  bastion_fqdn = "bastion.${local.cluster_base_domain_name}"

  # The URL below is generated by the authorized-keys-provider app running on cloud-platform-live-1.
  authorized_keys_url = "https://s3-eu-west-2.amazonaws.com/cloud-platform-ab9d0cbde59c3b3112de9d117068515d/authorized_keys"
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_ami" "debian_stretch_latest" {
  most_recent      = true
  executable_users = ["all"]
  owners           = ["379101102735"] // official Debian account (https://wiki.debian.org/Cloud/AmazonEC2Image/)

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// The EIP cannot be associated with the instance since it's in an autoscaling
// group. The host itself has a role which allows it and will do it on startup.
// See the userdata below for more detail.
resource "aws_eip" "bastion" {
  vpc = true

  tags = {
    "Name" = local.bastion_fqdn
  }
}

data "template_file" "authorized_keys_manager" {
  template = file(
    "${path.module}/resources/bastion/authorized_keys_manager.service",
  )

  vars = {
    authorized_keys_url = local.authorized_keys_url
  }
}

data "template_file" "configure_bastion" {
  template = file("${path.module}/resources/bastion/configure_bastion.sh")

  vars = {
    eip_id     = aws_eip.bastion.id
    aws_region = data.aws_region.current.name
  }
}

data "template_cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<EOF
packages:
- awscli
write_files:
- content: |
    ${indent(4, data.template_file.authorized_keys_manager.rendered)}
  owner: root:root
  path: /etc/systemd/system/authorized-keys-manager.service
- content: |
    ${indent(4, file("${path.module}/resources/bastion/sshd_config"))}
  owner: root:root
  path: /etc/ssh/sshd_config
EOF

  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.configure_bastion.rendered
  }
}

resource "aws_security_group" "bastion" {
  name        = local.bastion_fqdn
  description = "Security group for bastion"
  vpc_id      = module.cluster_vpc.vpc_id

  // non-standard port to reduce probes
  ingress {
    from_port   = 50422
    to_port     = 50422
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = local.bastion_fqdn
  }
}

data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "bastion" {
  name               = local.bastion_fqdn
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json
}

data "aws_iam_policy_document" "bastion" {
  statement {
    actions = [
      "ec2:AssociateAddress",
    ]

    // ec2:AssociateAddress cannot be constrained to a single eipalloc
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "bastion" {
  name   = "associate-eip"
  role   = aws_iam_role.bastion.id
  policy = data.aws_iam_policy_document.bastion.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = aws_route53_record.bastion.name
  role = aws_iam_role.bastion.name
}

resource "aws_launch_configuration" "bastion" {
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  image_id             = data.aws_ami.debian_stretch_latest.image_id
  instance_type        = "t2.nano"
  key_name             = aws_key_pair.cluster.key_name
  security_groups      = [aws_security_group.bastion.id]
  user_data            = data.template_cloudinit_config.bastion.rendered

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                      = local.bastion_fqdn
  desired_capacity          = "1"
  max_size                  = "1"
  min_size                  = "1"
  health_check_grace_period = 60
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = aws_launch_configuration.bastion.name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  vpc_zone_identifier = [module.cluster_vpc.public_subnets]
  default_cooldown    = 60

  tags = [
    {
      key                 = "Name"
      value               = local.bastion_fqdn
      propagate_at_launch = true
    },
  ]
}

resource "aws_route53_record" "bastion" {
  zone_id = module.cluster_dns.cluster_dns_zone_id
  name    = local.bastion_fqdn
  type    = "A"
  ttl     = "30"
  records = [aws_eip.bastion.public_ip]
}

