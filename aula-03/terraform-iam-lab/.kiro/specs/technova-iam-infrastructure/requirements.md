# Requirements Document

## Introduction

This document specifies the requirements for implementing a secure IAM (Identity and Access Management) infrastructure for TechNova using Terraform on AWS. The infrastructure enables secure access control across different teams (Development, Platform Engineering, and Interns) following the principle of least privilege. The system manages user access, enforces security boundaries with granular permissions, enables EC2 instances to access S3 securely without hardcoded credentials, and maintains clear audit trails through resource tagging.

## Glossary

- **IAM_System**: The Identity and Access Management infrastructure managed by Terraform
- **User**: An IAM user representing a team member
- **Group**: An IAM group that contains users with similar access needs
- **Policy**: An IAM policy that defines permissions
- **Service_Role**: An IAM role that AWS services can assume
- **Instance_Profile**: An AWS resource that passes an IAM role to an EC2 instance
- **Tag**: A key-value pair attached to AWS resources for identification and organization
- **Terraform**: The infrastructure-as-code tool used to manage AWS resources
- **Least_Privilege**: Security principle where entities are granted only the minimum permissions needed

## Requirements

### Requirement 1: User Management

**User Story:** As a system administrator, I want to create IAM users for team members, so that each person has individual access credentials and accountability.

#### Acceptance Criteria

1. THE IAM_System SHALL create a User named "juliana.santos" for Juliana Santos
2. THE IAM_System SHALL create a User named "rafael.oliveira" for Rafael Oliveira
3. THE IAM_System SHALL create a User named "lucas.intern" for Lucas
4. THE IAM_System SHALL NOT include hardcoded access keys or secret keys in the Terraform code
5. THE IAM_System SHALL add each User to their appropriate Groups based on team membership

### Requirement 2: Group Management

**User Story:** As a system administrator, I want to organize users into groups, so that I can manage permissions efficiently based on team roles.

#### Acceptance Criteria

1. THE IAM_System SHALL create a Group named "technova-developers"
2. THE IAM_System SHALL create a Group named "technova-platform-eng"
3. THE IAM_System SHALL create a Group named "technova-interns"
4. THE IAM_System SHALL add juliana.santos to the technova-developers Group
5. THE IAM_System SHALL add rafael.oliveira to both the technova-developers Group and the technova-platform-eng Group
6. THE IAM_System SHALL add lucas.intern to both the technova-developers Group and the technova-interns Group

### Requirement 3: Developer Policy

**User Story:** As a developer, I want read access to project data buckets, so that I can retrieve data needed for development work.

#### Acceptance Criteria

1. THE IAM_System SHALL create a Policy named "technova-developer-policy"
2. THE technova-developer-policy SHALL allow the s3:GetObject action on S3 buckets matching the pattern "technova-dados-*"
3. THE technova-developer-policy SHALL allow the s3:ListBucket action on S3 buckets matching the pattern "technova-dados-*"
4. THE technova-developer-policy SHALL allow the s3:GetBucketLocation action on S3 buckets matching the pattern "technova-dados-*"
5. THE IAM_System SHALL attach the technova-developer-policy to the technova-developers Group

### Requirement 4: Platform Engineering Policy

**User Story:** As a platform engineer, I want to manage EC2 instances for the TechNova project, so that I can maintain the infrastructure.

#### Acceptance Criteria

1. THE IAM_System SHALL create a Policy named "technova-platform-eng-policy"
2. THE technova-platform-eng-policy SHALL allow the ec2:StartInstances action
3. THE technova-platform-eng-policy SHALL allow the ec2:StopInstances action
4. THE technova-platform-eng-policy SHALL allow the ec2:RebootInstances action
5. THE technova-platform-eng-policy SHALL allow the ec2:DescribeInstances action
6. WHEN an EC2 instance has a tag "Project" with value "TechNova", THE technova-platform-eng-policy SHALL allow management actions on that instance
7. WHEN an EC2 instance does not have a tag "Project" with value "TechNova", THE technova-platform-eng-policy SHALL deny management actions on that instance
8. THE IAM_System SHALL attach the technova-platform-eng-policy to the technova-platform-eng Group

### Requirement 5: Intern Policy

**User Story:** As an intern, I want read-only access to resources, so that I can learn and observe without risk of accidental changes.

#### Acceptance Criteria

1. THE IAM_System SHALL create a Policy named "technova-intern-policy"
2. THE technova-intern-policy SHALL allow the s3:GetObject action on all S3 resources
3. THE technova-intern-policy SHALL allow the s3:ListBucket action on all S3 resources
4. THE technova-intern-policy SHALL allow the ec2:DescribeInstances action on all EC2 resources
5. THE technova-intern-policy SHALL allow the ec2:DescribeInstanceStatus action on all EC2 resources
6. THE technova-intern-policy SHALL explicitly deny the s3:DeleteObject action
7. THE technova-intern-policy SHALL explicitly deny the s3:PutObject action
8. THE technova-intern-policy SHALL explicitly deny the ec2:TerminateInstances action
9. THE technova-intern-policy SHALL explicitly deny the ec2:StopInstances action
10. THE technova-intern-policy SHALL explicitly deny the ec2:ModifyInstanceAttribute action
11. THE IAM_System SHALL attach the technova-intern-policy to the technova-interns Group

### Requirement 6: EC2 Service Role

**User Story:** As a system architect, I want EC2 instances to access S3 using temporary credentials, so that no credentials need to be hardcoded in applications.

#### Acceptance Criteria

1. THE IAM_System SHALL create a Service_Role named "technova-ec2-s3-access-role"
2. THE technova-ec2-s3-access-role SHALL have a trust policy that allows the EC2 service to assume the role
3. THE technova-ec2-s3-access-role SHALL allow the s3:GetObject action on S3 buckets matching the pattern "technova-app-data-*"
4. THE technova-ec2-s3-access-role SHALL allow the s3:PutObject action on S3 buckets matching the pattern "technova-app-data-*"
5. THE technova-ec2-s3-access-role SHALL allow the s3:ListBucket action on S3 buckets matching the pattern "technova-app-data-*"
6. THE technova-ec2-s3-access-role SHALL allow the s3:DeleteObject action on S3 buckets matching the pattern "technova-app-data-*"
7. THE IAM_System SHALL create an Instance_Profile named "technova-ec2-s3-instance-profile"
8. THE IAM_System SHALL associate the technova-ec2-s3-access-role with the technova-ec2-s3-instance-profile

### Requirement 7: Resource Tagging

**User Story:** As a system administrator, I want all IAM resources tagged consistently, so that I can track ownership, management method, and purpose.

#### Acceptance Criteria

1. THE IAM_System SHALL tag all Users with key "Project" and value "TechNova"
2. THE IAM_System SHALL tag all Users with key "ManagedBy" and value "Terraform"
3. THE IAM_System SHALL tag all Groups with key "Project" and value "TechNova"
4. THE IAM_System SHALL tag all Groups with key "ManagedBy" and value "Terraform"
5. THE IAM_System SHALL tag all Policies with key "Project" and value "TechNova"
6. THE IAM_System SHALL tag all Policies with key "ManagedBy" and value "Terraform"
7. THE IAM_System SHALL tag all Service_Roles with key "Project" and value "TechNova"
8. THE IAM_System SHALL tag all Service_Roles with key "ManagedBy" and value "Terraform"
9. THE IAM_System SHALL tag Users with key "Team" and an appropriate value based on their primary role
10. THE IAM_System SHALL tag Groups with key "Purpose" and an appropriate value describing the group's function
11. THE IAM_System SHALL tag Service_Roles with key "Purpose" and value "ServiceRole"

### Requirement 8: Code Organization

**User Story:** As a developer maintaining this infrastructure, I want the Terraform code organized into logical files, so that I can easily locate and modify specific resource types.

#### Acceptance Criteria

1. THE IAM_System SHALL define all Group resources in a file named "groups.tf"
2. THE IAM_System SHALL define all User resources and group memberships in a file named "users.tf"
3. THE IAM_System SHALL define all Policy documents and policy resources in a file named "policies.tf"
4. THE IAM_System SHALL define all policy attachment resources in a file named "attachments.tf"
5. THE IAM_System SHALL define all Service_Role and Instance_Profile resources in a file named "roles.tf"
6. THE IAM_System SHALL define all output values in a file named "outputs.tf"
7. THE provider configuration SHALL remain in the existing file named "providers.tf"

### Requirement 9: Output Values

**User Story:** As a system operator, I want to see key resource identifiers after deployment, so that I can reference them in other systems or verify the deployment.

#### Acceptance Criteria

1. THE IAM_System SHALL output a list of all User names with output name "user_names"
2. THE IAM_System SHALL output a list of all User ARNs with output name "user_arns"
3. THE IAM_System SHALL output a list of all Group names with output name "group_names"
4. THE IAM_System SHALL output a list of all Group ARNs with output name "group_arns"
5. THE IAM_System SHALL output a map of Policy ARNs with output name "policy_arns"
6. THE IAM_System SHALL output the Service_Role ARN with output name "ec2_role_arn"
7. THE IAM_System SHALL output the Service_Role name with output name "ec2_role_name"
8. THE IAM_System SHALL output the Instance_Profile name with output name "instance_profile_name"
9. THE IAM_System SHALL output the Instance_Profile ARN with output name "instance_profile_arn"

### Requirement 10: Security Validation

**User Story:** As a security engineer, I want the Terraform code to be valid and follow best practices, so that I can trust the infrastructure is secure and maintainable.

#### Acceptance Criteria

1. WHEN the command "terraform validate" is executed, THE IAM_System SHALL pass validation without errors
2. WHEN the command "terraform plan" is executed, THE IAM_System SHALL generate an execution plan without errors
3. THE IAM_System SHALL NOT contain any AWS access keys in the Terraform code
4. THE IAM_System SHALL NOT contain any AWS secret keys in the Terraform code
5. THE IAM_System SHALL use the AWS provider version constraint "~> 5.0"
6. THE IAM_System SHALL target the AWS region "us-east-1"
