# TechNova IAM Infrastructure Specification

## Overview
Implement secure IAM (Identity and Access Management) infrastructure for TechNova using Terraform on AWS (us-east-1 region). The solution follows the principle of least privilege and uses AWS best practices for access control.

## Business Context
TechNova needs a structured IAM setup to:
- Manage user access across different teams (Development, Platform Engineering, Interns)
- Enforce security boundaries with granular permissions
- Enable EC2 instances to access S3 securely without hardcoded credentials
- Maintain clear audit trails and resource organization through tags

## Requirements

### 1. Users
Create IAM users for the following team members:

| Name | Username | Teams | Access Level |
|------|----------|-------|--------------|
| Juliana Santos | juliana.santos | Development | Full dev access |
| Rafael Oliveira | rafael.oliveira | Development, Platform Engineering | Dev + infra access |
| Lucas | lucas.intern | Development (Intern) | Read-only access |

**Requirements:**
- No hardcoded access keys in code
- Users added to appropriate groups
- Standardized naming convention

### 2. Groups
Create three IAM groups with distinct purposes:

| Group Name | Purpose | Members |
|------------|---------|---------|
| `technova-developers` | All developers | Juliana, Rafael, Lucas |
| `technova-platform-eng` | Infrastructure team | Rafael |
| `technova-interns` | Interns with restricted access | Lucas |

### 3. Policies (Least Privilege)

#### 3.1 Developer Policy
**Policy Name:** `technova-developer-policy`

**Permissions:**
- Read access to S3 buckets matching pattern: `technova-dados-*`
- Actions allowed:
  - `s3:GetObject`
  - `s3:ListBucket`
  - `s3:GetBucketLocation`

**Attached to:** `technova-developers` group

#### 3.2 Platform Engineering Policy
**Policy Name:** `technova-platform-eng-policy`

**Permissions:**
- Manage EC2 instances with conditional access
- Actions allowed:
  - `ec2:StartInstances`
  - `ec2:StopInstances`
  - `ec2:RebootInstances`
  - `ec2:DescribeInstances`
- **Condition:** Only instances tagged with `Project=TechNova`

**Attached to:** `technova-platform-eng` group

#### 3.3 Intern Policy
**Policy Name:** `technova-intern-policy`

**Permissions:**
- Read-only access to S3 and EC2
- Allowed actions:
  - `s3:GetObject`
  - `s3:ListBucket`
  - `ec2:DescribeInstances`
  - `ec2:DescribeInstanceStatus`
- **Explicit Deny:** All destructive actions including:
  - `s3:DeleteObject`
  - `s3:PutObject`
  - `ec2:TerminateInstances`
  - `ec2:StopInstances`
  - `ec2:ModifyInstanceAttribute`

**Attached to:** `technova-interns` group

### 4. Service Role for EC2

#### 4.1 IAM Role
**Role Name:** `technova-ec2-s3-access-role`

**Purpose:** Allow EC2 instances to access S3 buckets securely using temporary credentials

**Trust Policy:**
- Allow EC2 service to assume this role

**Permissions:**
- Read/Write access to S3 buckets matching pattern: `technova-app-data-*`
- Actions allowed:
  - `s3:GetObject`
  - `s3:PutObject`
  - `s3:ListBucket`
  - `s3:DeleteObject`

#### 4.2 Instance Profile
**Instance Profile Name:** `technova-ec2-s3-instance-profile`

**Purpose:** Attach the IAM role to EC2 instances

**Associated Role:** `technova-ec2-s3-access-role`

### 5. Tagging Strategy

**Required Tags for All Resources:**

| Tag Key | Tag Value | Purpose |
|---------|-----------|---------|
| `Project` | `TechNova` | Identify project ownership |
| `ManagedBy` | `Terraform` | Infrastructure management method |
| `Team` or `Purpose` | Varies (e.g., `Development`, `Infrastructure`, `ServiceRole`) | Resource purpose/team |

### 6. File Organization

Terraform code must be organized into separate files:

| File | Purpose |
|------|---------|
| `providers.tf` | Provider configuration (already exists) |
| `groups.tf` | IAM group definitions |
| `users.tf` | IAM user definitions and group memberships |
| `policies.tf` | IAM policy documents and policy resources |
| `attachments.tf` | Policy attachments to groups |
| `roles.tf` | IAM roles and instance profiles |
| `outputs.tf` | Output values |

### 7. Outputs

The following outputs must be exposed:

| Output Name | Value | Description |
|-------------|-------|-------------|
| `user_names` | List of user names | All created IAM users |
| `user_arns` | List of user ARNs | ARNs of all IAM users |
| `group_names` | List of group names | All created IAM groups |
| `group_arns` | List of group ARNs | ARNs of all IAM groups |
| `policy_arns` | Map of policy ARNs | ARNs of all custom policies |
| `ec2_role_arn` | Role ARN | ARN of EC2 S3 access role |
| `ec2_role_name` | Role name | Name of EC2 S3 access role |
| `instance_profile_name` | Instance profile name | Name of EC2 instance profile |
| `instance_profile_arn` | Instance profile ARN | ARN of EC2 instance profile |

## Security Requirements

1. **No Hardcoded Credentials:**
   - No AWS access keys or secret keys in code
   - Use AWS CLI profiles or environment variables for authentication

2. **Least Privilege:**
   - Each policy grants only minimum required permissions
   - Use resource constraints and conditions where applicable

3. **Explicit Denies:**
   - Intern policy includes explicit deny statements for destructive actions
   - Deny takes precedence over any allow statements

4. **Conditional Access:**
   - Platform Engineering policy uses tag-based conditions
   - Ensures resources can only be managed if properly tagged

5. **Service Roles:**
   - EC2 instances use IAM roles instead of embedded credentials
   - Temporary credentials automatically rotated by AWS

## Validation Criteria

### Success Criteria:
1. ✅ All users created with correct group memberships
2. ✅ All groups created and linked to appropriate policies
3. ✅ All policies implement least privilege principles
4. ✅ Intern policy explicitly denies destructive actions
5. ✅ Platform Engineering policy restricted to tagged instances
6. ✅ EC2 role and instance profile created successfully
7. ✅ All resources properly tagged
8. ✅ All outputs display correctly after `terraform apply`
9. ✅ Code organized into specified separate files
10. ✅ `terraform validate` passes without errors
11. ✅ `terraform plan` shows expected resource creation

### Testing:
- Run `terraform init` to initialize providers
- Run `terraform validate` to check syntax
- Run `terraform plan` to preview changes
- Review plan output for security compliance
- Run `terraform apply` to create resources
- Verify outputs match requirements

## Implementation Notes

### Policy Testing Considerations:
While the infrastructure will be created, actual policy effectiveness testing would require:
- Creating test S3 buckets (`technova-dados-test`, `technova-app-data-test`)
- Creating test EC2 instances with `Project=TechNova` tag
- Using AWS CloudShell or AWS CLI with user credentials to test permissions
- Verifying deny statements prevent unauthorized actions

### Best Practices:
- Use Terraform formatting: `terraform fmt`
- Use meaningful resource names
- Add comments for complex policy logic
- Keep policy documents readable with proper JSON formatting
- Use Terraform variables for repeated values (if needed later)

## Dependencies

### Required Tools:
- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS CLI (for authentication)
- Valid AWS credentials with IAM permissions

### AWS Permissions Required:
The Terraform executor needs permissions to:
- Create/manage IAM users, groups, policies
- Create/manage IAM roles and instance profiles
- Tag IAM resources

## Future Enhancements (Out of Scope)

- MFA enforcement for users
- Password policy configuration
- Access key rotation policies
- CloudTrail logging for IAM events
- Cost allocation tags
- Cross-account role assumptions
- SSO integration

---

**Document Version:** 1.0  
**Last Updated:** 2026-09-08  
**Status:** Ready for Implementation
