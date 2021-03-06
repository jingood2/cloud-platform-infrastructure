locals {
  live_domain = "cloud-platform-live"

  allowed_live_ips = {
    "52.17.133.167/32"  = "live-0-a"
    "34.247.134.240/32" = "live-0-b"
    "34.251.93.81/32"   = "live-0-c"
  }

  allowed_live_1_ips = {
    "35.178.209.113/32" = "live-1-a"
    "35.177.252.54/32"  = "live-1-b"
    "3.8.51.207/32"     = "live-1-c"
  }

  audit_domain = "cloud-platform-audit"

  allowed_audit_ips = local.allowed_live_ips

  allowed_audit_1_ips = local.allowed_live_1_ips

  test_domain = "cloud-platform-test"

  allowed_test_ips = {
    "3.10.134.18/32"     = "?"
    "3.10.182.216/32"    = "?"
    "3.10.148.25/32"     = "?"
    "35.178.209.113/32"  = "?"
    "35.177.252.54/32"   = "?"
    "3.8.51.207/32"      = "?"
    "88.98.227.149/32"   = "?"
    "82.46.130.162/32"   = "?"
    "35.178.31.199/32"   = "?"
    "3.9.196.241/32"     = "?"
    "3.10.159.29/32"     = "?"
    "213.121.161.124/32" = "102PFWifi"
    "81.134.202.29/32"   = "MoJDigital"
  }
}

data "aws_region" "moj-dsd" {
}

data "aws_caller_identity" "moj-dsd" {
}

data "aws_region" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_caller_identity" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_iam_policy_document" "live" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-dsd.name}:${data.aws_caller_identity.moj-dsd.account_id}:domain/${local.live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_live_ips)
    }
  }
}

data "aws_iam_policy_document" "live_1" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_live_1_ips)
    }
  }
}

resource "aws_elasticsearch_domain" "live" {
  domain_name           = local.live_domain
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type            = "m4.xlarge.elasticsearch"
    instance_count           = "4"
    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.live.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.live_domain
  }
}

resource "aws_elasticsearch_domain" "live_1" {
  domain_name           = local.live_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type            = "m4.2xlarge.elasticsearch"
    instance_count           = "6"
    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.live_1.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.live_domain
  }
}

data "aws_iam_policy_document" "audit" {
  statement {
    actions = [
      "es:AddTags",
      "es:ESHttpHead",
      "es:DescribeElasticsearchDomain",
      "es:ESHttpPost",
      "es:ESHttpGet",
      "es:ESHttpPut",
      "es:DescribeElasticsearchDomainConfig",
      "es:ListTags",
      "es:DescribeElasticsearchDomains",
      "es:ListDomainNames",
      "es:ListElasticsearchInstanceTypes",
      "es:DescribeElasticsearchInstanceTypeLimits",
      "es:ListElasticsearchVersions",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-dsd.name}:${data.aws_caller_identity.moj-dsd.account_id}:domain/${local.audit_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_audit_ips)
    }
  }
}

data "aws_iam_policy_document" "audit_1" {
  statement {
    actions = [
      "es:AddTags",
      "es:ESHttpHead",
      "es:DescribeElasticsearchDomain",
      "es:ESHttpPost",
      "es:ESHttpGet",
      "es:ESHttpPut",
      "es:DescribeElasticsearchDomainConfig",
      "es:ListTags",
      "es:DescribeElasticsearchDomains",
      "es:ListDomainNames",
      "es:ListElasticsearchInstanceTypes",
      "es:DescribeElasticsearchInstanceTypeLimits",
      "es:ListElasticsearchVersions",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.audit_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_audit_1_ips)
    }
  }
}

resource "aws_elasticsearch_domain" "audit" {
  domain_name           = local.audit_domain
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type  = "m4.xlarge.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.audit.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.audit_domain
  }

  log_publishing_options {
    cloudwatch_log_group_arn = ""
    enabled                  = false
    log_type                 = "ES_APPLICATION_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = ""
    enabled                  = false
    log_type                 = "INDEX_SLOW_LOGS"
  }
}

# audit cluster for live-1
resource "aws_elasticsearch_domain" "audit_1" {
  domain_name           = local.audit_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "6.5"

  cluster_config {
    instance_type          = "m4.xlarge.elasticsearch"
    instance_count         = "6"
    zone_awareness_enabled = true
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.audit_1.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.audit_domain
  }
}

data "aws_iam_policy_document" "test" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.test_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(merge(local.allowed_live_1_ips, local.allowed_test_ips))
    }
  }
}

resource "aws_elasticsearch_domain" "test" {
  domain_name           = "cloud-platform-test"
  provider              = aws.cloud-platform
  elasticsearch_version = "7.1"

  cluster_config {
    instance_type  = "r5.xlarge.elasticsearch"
    instance_count = "1"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "500"
  }

  access_policies = data.aws_iam_policy_document.test.json

  log_publishing_options {
    cloudwatch_log_group_arn = ""
    enabled                  = false
    log_type                 = "ES_APPLICATION_LOGS"
  }
}

