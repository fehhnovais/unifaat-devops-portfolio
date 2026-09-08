# IAM Roles and Instance Profiles for TechNova

# Trust policy allowing EC2 service to assume the role
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# EC2 service role for S3 access
resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "technova-ec2-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "ServiceRole"
  }
}

# Policy document for S3 access to technova-app-data-* buckets
data "aws_iam_policy_document" "ec2_s3_access_policy" {
  statement {
    sid    = "S3FullAccessToAppData"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::technova-app-data-*",
      "arn:aws:s3:::technova-app-data-*/*"
    ]
  }
}

# Inline policy attached to the EC2 role
resource "aws_iam_role_policy" "ec2_s3_access_policy" {
  name   = "technova-ec2-s3-access-policy"
  role   = aws_iam_role.ec2_s3_access_role.id
  policy = data.aws_iam_policy_document.ec2_s3_access_policy.json
}

# Instance Profile for EC2 to assume the S3 access role
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "technova-ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "ServiceRole"
  }
}
