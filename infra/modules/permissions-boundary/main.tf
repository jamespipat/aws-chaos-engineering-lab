resource "aws_iam_policy" "this" {
  name        = var.name
  description = "Limits lab workload and FIS roles to the services this platform uses."
  policy      = data.aws_iam_policy_document.this.json
  tags        = var.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "LabServices"
    effect = "Allow"
    actions = [
      "s3:*",
      "sqs:*",
      "logs:*",
      "cloudwatch:*",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "rds-db:connect",
      "eks:DescribeCluster",
      "ec2:Describe*",
      "fis:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyIdentityAdmin"
    effect = "Deny"
    actions = [
      "iam:*",
      "organizations:*",
      "account:*",
    ]
    resources = ["*"]
  }
}
