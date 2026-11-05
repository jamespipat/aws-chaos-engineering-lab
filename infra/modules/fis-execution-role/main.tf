data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["fis.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:fis:${var.region}:${var.account_id}:experiment/*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

data "aws_iam_policy_document" "actions" {
  statement {
    sid       = "DescribeLabCluster"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    sid = "ReadNetworkTargets"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeSubnets",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ReadStopAlarms"
    actions   = ["cloudwatch:DescribeAlarms"]
    resources = var.alarm_arns
  }

  statement {
    sid = "WriteLabLogGroup"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [var.log_group_arn, "${var.log_group_arn}:*"]
  }

  statement {
    sid = "ExperimentLogDelivery"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    # These log-delivery APIs do not accept a log group ARN.
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "actions" {
  name   = "${var.name}-actions"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.actions.json
}
