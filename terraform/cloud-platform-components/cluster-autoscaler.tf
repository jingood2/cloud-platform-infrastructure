
# cluster-autoscaler
# HELM

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "stable"
  chart      = "cluster-autoscaler"

  namespace = "kube-system"
  version   = "5.0.0"

  values = [templatefile("${path.module}/templates/cluster-autoscaler.yaml.tpl", {
    cluster_name = terraform.workspace
    iam_role     = aws_iam_role.clusterautoscaler.name
  })]

}

# KIAM role creation

data "aws_iam_policy_document" "clusterautoscaler_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}

resource "aws_iam_role" "clusterautoscaler" {
  name               = "autoscaler.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.clusterautoscaler_assume.json
}


data "aws_iam_policy_document" "clusterautoscaler" {

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "clusterautoscaler_policy" {
  name   = "cluster-autoscaler"
  role   = aws_iam_role.clusterautoscaler.id
  policy = data.aws_iam_policy_document.clusterautoscaler.json
}
