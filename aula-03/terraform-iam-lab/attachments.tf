# TechNova IAM Policy Attachments
# This file manages policy-to-group attachments

# Attach Developer Policy to Developers Group
resource "aws_iam_group_policy_attachment" "developers_policy_attachment" {
  group      = aws_iam_group.technova_developers.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

# Attach Platform Engineering Policy to Platform Engineering Group
resource "aws_iam_group_policy_attachment" "platform_eng_policy_attachment" {
  group      = aws_iam_group.technova_platform_eng.name
  policy_arn = aws_iam_policy.platform_eng_policy.arn
}

# Attach Intern Policy to Interns Group
resource "aws_iam_group_policy_attachment" "interns_policy_attachment" {
  group      = aws_iam_group.technova_interns.name
  policy_arn = aws_iam_policy.intern_policy.arn
}
