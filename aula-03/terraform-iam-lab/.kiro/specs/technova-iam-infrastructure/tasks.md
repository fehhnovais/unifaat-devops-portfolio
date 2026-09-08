# Implementation Plan: TechNova IAM Infrastructure

## Overview

This implementation plan breaks down the Terraform IAM infrastructure into discrete coding tasks. Each task builds on previous work to create a complete, secure IAM setup for TechNova. The approach follows Terraform best practices with organized file structure, type-safe policy documents, and comprehensive testing at each stage.

## Tasks

- [x] 1. Create IAM groups
  - [x] 1.1 Implement groups.tf with all three IAM groups
    - Create `aws_iam_group` resources for technova-developers, technova-platform-eng, and technova-interns
    - Add required tags (Project, ManagedBy, Purpose) to each group
    - _Requirements: 2.1, 2.2, 2.3, 7.3, 7.4, 7.10_

- [x] 2. Create IAM users and group memberships
  - [x] 2.1 Implement users.tf with all user resources
    - Create `aws_iam_user` resources for juliana.santos, rafael.oliveira, and lucas.intern
    - Add required tags (Project, ManagedBy, Team) to each user
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.1, 7.2, 7.9_
  
  - [x] 2.2 Add group membership associations
    - Create `aws_iam_user_group_membership` resources linking users to their groups
    - Juliana → technova-developers
    - Rafael → technova-developers + technova-platform-eng
    - Lucas → technova-developers + technova-interns
    - _Requirements: 1.5, 2.4, 2.5, 2.6_

- [~] 3. Checkpoint - Validate users and groups
  - Run `terraform fmt` to format code
  - Run `terraform validate` to check syntax
  - Run `terraform plan` to preview user and group creation
  - Ensure all tests pass, ask the user if questions arise

- [x] 4. Create IAM policies
  - [x] 4.1 Implement developer policy in policies.tf
    - Create `data "aws_iam_policy_document"` for developer permissions
    - Create `aws_iam_policy` resource for technova-developer-policy
    - Grant s3:GetObject, s3:ListBucket, s3:GetBucketLocation on technova-dados-* buckets
    - Add required tags (Project, ManagedBy, Purpose)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.5, 7.6_
  
  - [x] 4.2 Implement platform engineering policy in policies.tf
    - Create `data "aws_iam_policy_document"` for platform engineer permissions
    - Include two statements: conditional EC2 management + unconditional describe
    - Add condition for tag "Project=TechNova" on management actions
    - Create `aws_iam_policy` resource for technova-platform-eng-policy
    - Add required tags
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 7.5, 7.6_
  
  - [x] 4.3 Implement intern policy in policies.tf
    - Create `data "aws_iam_policy_document"` with three statements: S3 read, EC2 read, explicit denies
    - Add explicit deny statement for destructive actions (s3:DeleteObject, s3:PutObject, ec2:TerminateInstances, ec2:StopInstances, ec2:ModifyInstanceAttribute)
    - Create `aws_iam_policy` resource for technova-intern-policy
    - Add required tags
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 7.5, 7.6_

- [x] 5. Create policy attachments
  - [x] 5.1 Implement attachments.tf with all policy-to-group attachments
    - Create `aws_iam_group_policy_attachment` for developer policy → technova-developers group
    - Create `aws_iam_group_policy_attachment` for platform-eng policy → technova-platform-eng group
    - Create `aws_iam_group_policy_attachment` for intern policy → technova-interns group
    - _Requirements: 3.5, 4.8, 5.11_

- [~] 6. Checkpoint - Validate policies and attachments
  - Run `terraform fmt` to format code
  - Run `terraform validate` to check policy syntax
  - Run `terraform plan` to preview policy creation and attachments
  - Review policy documents for security compliance (least privilege, explicit denies)
  - Ensure all tests pass, ask the user if questions arise

- [x] 7. Create IAM role and instance profile for EC2
  - [x] 7.1 Implement EC2 service role in roles.tf
    - Create `data "aws_iam_policy_document"` for EC2 assume role trust policy
    - Create `aws_iam_role` resource for technova-ec2-s3-access-role
    - Add required tags (Project, ManagedBy, Purpose=ServiceRole)
    - _Requirements: 6.1, 6.2, 7.7, 7.8, 7.11_
  
  - [x] 7.2 Add inline policy to EC2 role
    - Create `data "aws_iam_policy_document"` for S3 permissions on technova-app-data-* buckets
    - Create `aws_iam_role_policy` resource with S3 read/write permissions (s3:GetObject, s3:PutObject, s3:ListBucket, s3:DeleteObject)
    - _Requirements: 6.3, 6.4, 6.5, 6.6_
  
  - [x] 7.3 Create instance profile
    - Create `aws_iam_instance_profile` resource for technova-ec2-s3-instance-profile
    - Associate with technova-ec2-s3-access-role
    - Add required tags
    - _Requirements: 6.7, 6.8_

- [x] 8. Create outputs
  - [x] 8.1 Implement outputs.tf with all required outputs
    - Output user_names (list of user names)
    - Output user_arns (list of user ARNs)
    - Output group_names (list of group names)
    - Output group_arns (list of group ARNs)
    - Output policy_arns (map of policy ARNs)
    - Output ec2_role_arn (EC2 role ARN)
    - Output ec2_role_name (EC2 role name)
    - Output instance_profile_name (instance profile name)
    - Output instance_profile_arn (instance profile ARN)
    - Add descriptions to all outputs
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9_

- [x] 9. Final validation and compliance checks
  - [x] 9.1 Run comprehensive Terraform validation
    - Run `terraform fmt -recursive` to format all files
    - Run `terraform validate` to check complete configuration
    - Run `terraform plan` and review full execution plan
    - Verify plan shows creation of 3 users, 3 groups, 3 policies, 3 attachments, 1 role, 1 instance profile
    - _Requirements: 10.1, 10.2_
  
  - [ ]* 9.2 Perform security compliance checks
    - Search codebase for hardcoded credentials patterns (AKIA*, aws_access_key_id, aws_secret_access_key)
    - Verify all resources have required tags
    - Review each policy for least privilege compliance
    - Confirm intern policy contains explicit deny statements
    - Verify platform-eng policy uses conditional access with tags
    - _Requirements: 10.3, 10.4_
  
  - [ ]* 9.3 Verify provider configuration
    - Confirm AWS provider version constraint is "~> 5.0"
    - Confirm target region is "us-east-1"
    - _Requirements: 10.5, 10.6_

- [x] 10. Final checkpoint - Ready for deployment
  - All Terraform validation passes
  - All security compliance checks pass
  - Code is properly formatted and organized
  - Ask the user if they want to proceed with `terraform apply` or if any adjustments are needed

## Notes

- Tasks marked with `*` are optional security validation checks that can be skipped for faster implementation
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation and catch issues early
- No property-based tests are included since this is Infrastructure as Code (declarative configuration)
- Testing strategy focuses on Terraform validation, policy syntax checks, and manual integration tests
- All code should be formatted with `terraform fmt` before committing
- Review Terraform plan output carefully before applying changes

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["2.2"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3"] },
    { "id": 4, "tasks": ["5.1"] },
    { "id": 5, "tasks": ["7.1"] },
    { "id": 6, "tasks": ["7.2"] },
    { "id": 7, "tasks": ["7.3"] },
    { "id": 8, "tasks": ["8.1"] },
    { "id": 9, "tasks": ["9.1", "9.2", "9.3"] }
  ]
}
```
