# IAM Users for TechNova Team Members

resource "aws_iam_user" "juliana_santos" {
  name = "juliana.santos"

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Team      = "Development"
  }
}

resource "aws_iam_user" "rafael_oliveira" {
  name = "rafael.oliveira"

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Team      = "Infrastructure"
  }
}

resource "aws_iam_user" "lucas_intern" {
  name = "lucas.intern"

  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Team      = "Development"
  }
}
# Group Membership Associations

resource "aws_iam_user_group_membership" "juliana_membership" {
  user = aws_iam_user.juliana_santos.name

  groups = [
    aws_iam_group.technova_developers.name
  ]
}

resource "aws_iam_user_group_membership" "rafael_membership" {
  user = aws_iam_user.rafael_oliveira.name

  groups = [
    aws_iam_group.technova_developers.name,
    aws_iam_group.technova_platform_eng.name
  ]
}

resource "aws_iam_user_group_membership" "lucas_membership" {
  user = aws_iam_user.lucas_intern.name

  groups = [
    aws_iam_group.technova_developers.name,
    aws_iam_group.technova_interns.name
  ]
}
