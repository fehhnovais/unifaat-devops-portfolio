# IAM Groups for TechNova
# Note: AWS IAM groups do not support tagging

resource "aws_iam_group" "technova_developers" {
  name = "technova-developers"
}

resource "aws_iam_group" "technova_platform_eng" {
  name = "technova-platform-eng"
}

resource "aws_iam_group" "technova_interns" {
  name = "technova-interns"
}
