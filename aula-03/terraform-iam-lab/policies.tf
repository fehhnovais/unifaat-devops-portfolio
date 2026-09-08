# TechNova IAM Policies
# This file defines custom IAM policies for different team roles

# Developer Policy Document
data "aws_iam_policy_document" "developer_policy" {
  statement {
    sid    = "S3ReadAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::technova-dados-*",
      "arn:aws:s3:::technova-dados-*/*"
    ]
  }
}

# Developer Policy Resource
resource "aws_iam_policy" "developer_policy" {
  name        = "technova-developer-policy"
  description = "Read-only access to TechNova data buckets"
  policy      = data.aws_iam_policy_document.developer_policy.json

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "Development"
  }
}

# Platform Engineering Policy Document
data "aws_iam_policy_document" "platform_eng_policy" {
  statement {
    sid    = "EC2ManagementConditional"
    effect = "Allow"

    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances"
    ]

    resources = ["arn:aws:ec2:us-east-1:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Project"
      values   = ["TechNova"]
    }
  }

  statement {
    sid    = "EC2DescribeAccess"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

    resources = ["*"]
  }
}

# Platform Engineering Policy Resource
resource "aws_iam_policy" "platform_eng_policy" {
  name        = "technova-platform-eng-policy"
  description = "Manage EC2 instances tagged with Project=TechNova"
  policy      = data.aws_iam_policy_document.platform_eng_policy.json

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "Infrastructure"
  }
}

# Intern Policy Document
data "aws_iam_policy_document" "intern_policy" {
  statement {
    sid    = "S3ReadOnlyAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "EC2ReadOnlyAccess"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ExplicitDenyDestructiveActions"
    effect = "Deny"

    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:ModifyInstanceAttribute"
    ]

    resources = ["*"]
  }
}

# Intern Policy Resource
resource "aws_iam_policy" "intern_policy" {
  name        = "technova-intern-policy"
  description = "Read-only access with explicit denies for destructive actions"
  policy      = data.aws_iam_policy_document.intern_policy.json

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "Intern"
  }
}
