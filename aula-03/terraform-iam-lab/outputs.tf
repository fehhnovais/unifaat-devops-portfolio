# TechNova IAM Infrastructure Outputs
# This file exposes key resource identifiers for reference and verification

# User Outputs
output "user_names" {
  description = "List of all IAM user names"
  value = [
    aws_iam_user.juliana_santos.name,
    aws_iam_user.rafael_oliveira.name,
    aws_iam_user.lucas_intern.name
  ]
}

output "user_arns" {
  description = "List of all IAM user ARNs"
  value = [
    aws_iam_user.juliana_santos.arn,
    aws_iam_user.rafael_oliveira.arn,
    aws_iam_user.lucas_intern.arn
  ]
}

# Group Outputs
output "group_names" {
  description = "List of all IAM group names"
  value = [
    aws_iam_group.technova_developers.name,
    aws_iam_group.technova_platform_eng.name,
    aws_iam_group.technova_interns.name
  ]
}

output "group_arns" {
  description = "List of all IAM group ARNs"
  value = [
    aws_iam_group.technova_developers.arn,
    aws_iam_group.technova_platform_eng.arn,
    aws_iam_group.technova_interns.arn
  ]
}

# Policy Outputs
output "policy_arns" {
  description = "Map of custom policy ARNs"
  value = {
    developer_policy    = aws_iam_policy.developer_policy.arn
    platform_eng_policy = aws_iam_policy.platform_eng_policy.arn
    intern_policy       = aws_iam_policy.intern_policy.arn
  }
}

# EC2 Role Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 S3 access role"
  value       = aws_iam_role.ec2_s3_access_role.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 S3 access role"
  value       = aws_iam_role.ec2_s3_access_role.name
}

# Instance Profile Outputs
output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.arn
}
