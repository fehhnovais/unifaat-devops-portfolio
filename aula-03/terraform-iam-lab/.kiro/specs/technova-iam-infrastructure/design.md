# Design Document: TechNova IAM Infrastructure

## Overview

This design document describes the Terraform implementation for TechNova's AWS IAM infrastructure. The system creates a secure, role-based access control (RBAC) structure with three user groups (developers, platform engineers, and interns), custom IAM policies following the principle of least privilege, and an EC2 service role for S3 access. All resources are deployed to AWS us-east-1 region using Terraform 1.0+ with AWS Provider 5.x.

The design emphasizes:
- **Security**: No hardcoded credentials, explicit denies for interns, conditional access for platform engineers
- **Maintainability**: Organized file structure, consistent naming, comprehensive tagging
- **Auditability**: Clear outputs, resource tagging for ownership tracking

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS IAM Infrastructure                    │
│                         (us-east-1)                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Users                    Groups                   Policies  │
│  ┌──────────────┐        ┌──────────────┐       ┌─────────┐│
│  │ juliana.     │───────▶│ technova-    │◀──────│Developer││
│  │ santos       │        │ developers   │       │Policy   ││
│  └──────────────┘        └──────────────┘       └─────────┘│
│                                                               │
│  ┌──────────────┐        ┌──────────────┐       ┌─────────┐│
│  │ rafael.      │───────▶│ technova-    │◀──────│Platform ││
│  │ oliveira     │───┐    │ platform-eng │       │Eng      ││
│  └──────────────┘   │    └──────────────┘       │Policy   ││
│                     │                            └─────────┘│
│                     │    ┌──────────────┐                   │
│                     └───▶│ technova-    │       ┌─────────┐│
│  ┌──────────────┐        │ developers   │◀──────│Developer││
│  │ lucas.       │───┐    └──────────────┘       │Policy   ││
│  │ intern       │   │                            └─────────┘│
│  └──────────────┘   │    ┌──────────────┐                   │
│                     └───▶│ technova-    │◀──────┌─────────┐│
│                          │ interns      │       │Intern   ││
│                          └──────────────┘       │Policy   ││
│                                                  └─────────┘│
│                                                               │
│  EC2 Service Role                                            │
│  ┌────────────────────────────────────────────┐             │
│  │ technova-ec2-s3-access-role                │             │
│  │ ┌────────────────────────────────────┐    │             │
│  │ │ Trust Policy: EC2 Service          │    │             │
│  │ └────────────────────────────────────┘    │             │
│  │ ┌────────────────────────────────────┐    │             │
│  │ │ Permissions: S3 Read/Write         │    │             │
│  │ │ (technova-app-data-* buckets)      │    │             │
│  │ └────────────────────────────────────┘    │             │
│  └────────────────────────────────────────────┘             │
│               │                                               │
│               ▼                                               │
│  ┌────────────────────────────────────────────┐             │
│  │ technova-ec2-s3-instance-profile           │             │
│  └────────────────────────────────────────────┘             │
│                                                               │
└─────────────────────────────────────────────────────────────┘

Managed by: Terraform
```

### File Organization

The Terraform code is organized into seven files for clarity and maintainability:

```
terraform-iam-lab/
├── providers.tf         # AWS provider configuration (existing)
├── groups.tf           # IAM group definitions
├── users.tf            # IAM users and group memberships
├── policies.tf         # IAM policy documents and resources
├── attachments.tf      # Policy-to-group attachments
├── roles.tf            # IAM roles and instance profiles
└── outputs.tf          # Output values
```

## Components and Interfaces

### 1. IAM Users (users.tf)

**Purpose**: Create individual IAM users for team members.

**Resources**:
- `aws_iam_user.juliana_santos`
- `aws_iam_user.rafael_oliveira`
- `aws_iam_user.lucas_intern`
- `aws_iam_user_group_membership.juliana_membership`
- `aws_iam_user_group_membership.rafael_membership`
- `aws_iam_user_group_membership.lucas_membership`

**Configuration**:
```hcl
resource "aws_iam_user" "juliana_santos" {
  name = "juliana.santos"
  
  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Team      = "Development"
  }
}

resource "aws_iam_user_group_membership" "juliana_membership" {
  user = aws_iam_user.juliana_santos.name
  
  groups = [
    aws_iam_group.technova_developers.name
  ]
}
```

**Key Design Decisions**:
- Use underscores in resource names (terraform convention) but dots in IAM usernames (matches email format)
- Group memberships managed via `aws_iam_user_group_membership` for clear association
- Tags include `Team` to identify user's primary role

### 2. IAM Groups (groups.tf)

**Purpose**: Organize users into logical access groups.

**Resources**:
- `aws_iam_group.technova_developers`
- `aws_iam_group.technova_platform_eng`
- `aws_iam_group.technova_interns`

**Configuration**:
```hcl
resource "aws_iam_group" "technova_developers" {
  name = "technova-developers"
  
  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "Development"
  }
}
```

**Key Design Decisions**:
- Hyphenated naming convention for groups (AWS best practice)
- Tags include `Purpose` to describe group function
- Groups have no direct policy attachments (managed separately in attachments.tf)

### 3. IAM Policies (policies.tf)

**Purpose**: Define permission policies with least privilege principle.

**Resources**:
- `aws_iam_policy.developer_policy`
- `aws_iam_policy.platform_eng_policy`
- `aws_iam_policy.intern_policy`
- Inline policy documents using `data "aws_iam_policy_document"`

#### 3.1 Developer Policy

**Permissions**: Read-only access to S3 buckets matching `technova-dados-*`

```hcl
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
```

**Key Design Decisions**:
- Use `aws_iam_policy_document` data source for type-safe policy generation
- Separate SID for clarity in CloudTrail logs
- Resource ARN includes both bucket and object levels

#### 3.2 Platform Engineering Policy

**Permissions**: Manage EC2 instances tagged with `Project=TechNova`

```hcl
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
```

**Key Design Decisions**:
- Two separate statements: conditional management actions + unconditional describe
- `ec2:DescribeInstances` requires `"*"` resource (AWS limitation)
- Condition restricts management to tagged instances only
- Tag-based condition enforces resource boundaries

#### 3.3 Intern Policy

**Permissions**: Read-only with explicit denies for destructive actions

```hcl
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
```

**Key Design Decisions**:
- Three separate statements for clarity: S3 read, EC2 read, explicit denies
- Explicit `Deny` statement ensures interns cannot perform destructive actions even if granted elsewhere
- Deny takes precedence over any Allow in IAM evaluation logic

### 4. Policy Attachments (attachments.tf)

**Purpose**: Associate policies with groups.

**Resources**:
- `aws_iam_group_policy_attachment.developers_policy_attachment`
- `aws_iam_group_policy_attachment.platform_eng_policy_attachment`
- `aws_iam_group_policy_attachment.interns_policy_attachment`

**Configuration**:
```hcl
resource "aws_iam_group_policy_attachment" "developers_policy_attachment" {
  group      = aws_iam_group.technova_developers.name
  policy_arn = aws_iam_policy.developer_policy.arn
}
```

**Key Design Decisions**:
- Separate file for attachments improves readability
- One attachment per group-policy pair
- Clear dependency chain: groups → policies → attachments

### 5. IAM Roles and Instance Profiles (roles.tf)

**Purpose**: Enable EC2 instances to access S3 without hardcoded credentials.

**Resources**:
- `aws_iam_role.ec2_s3_access_role`
- `aws_iam_role_policy.ec2_s3_access_policy`
- `aws_iam_instance_profile.ec2_s3_instance_profile`

#### 5.1 EC2 Service Role

**Trust Policy**: Allow EC2 service to assume role

```hcl
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

resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "technova-ec2-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  
  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "ServiceRole"
  }
}
```

**Permissions Policy**: Read/write access to `technova-app-data-*` buckets

```hcl
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

resource "aws_iam_role_policy" "ec2_s3_access_policy" {
  name   = "technova-ec2-s3-access-policy"
  role   = aws_iam_role.ec2_s3_access_role.id
  policy = data.aws_iam_policy_document.ec2_s3_access_policy.json
}
```

#### 5.2 Instance Profile

**Purpose**: Attach role to EC2 instances

```hcl
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "technova-ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name
  
  tags = {
    Project   = "TechNova"
    ManagedBy = "Terraform"
    Purpose   = "ServiceRole"
  }
}
```

**Key Design Decisions**:
- Use inline role policy (`aws_iam_role_policy`) instead of separate policy resource for service roles
- Trust policy uses `data.aws_iam_policy_document` for consistency
- Instance profile name matches role name for clarity

### 6. Outputs (outputs.tf)

**Purpose**: Expose key resource identifiers for reference and verification.

**Configuration**:
```hcl
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

output "policy_arns" {
  description = "Map of custom policy ARNs"
  value = {
    developer_policy    = aws_iam_policy.developer_policy.arn
    platform_eng_policy = aws_iam_policy.platform_eng_policy.arn
    intern_policy       = aws_iam_policy.intern_policy.arn
  }
}

output "ec2_role_arn" {
  description = "ARN of the EC2 S3 access role"
  value       = aws_iam_role.ec2_s3_access_role.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 S3 access role"
  value       = aws_iam_role.ec2_s3_access_role.name
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.arn
}
```

**Key Design Decisions**:
- Use lists for users and groups (consistent ordering)
- Use map for policy ARNs (named access)
- Include both names and ARNs for flexibility
- Descriptions explain each output's purpose

## Data Models

### Resource Naming Convention

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| IAM Users | `{firstname}.{lastname}` or `{firstname}.{role}` | `juliana.santos`, `lucas.intern` |
| IAM Groups | `technova-{team-name}` | `technova-developers` |
| IAM Policies | `technova-{team-name}-policy` | `technova-developer-policy` |
| IAM Roles | `technova-{purpose}-role` | `technova-ec2-s3-access-role` |
| Instance Profiles | `technova-{purpose}-instance-profile` | `technova-ec2-s3-instance-profile` |

### Tagging Schema

All resources include these mandatory tags:

| Tag Key | Tag Value | Applied To |
|---------|-----------|------------|
| `Project` | `TechNova` | All resources |
| `ManagedBy` | `Terraform` | All resources |
| `Team` | `Development`, `Infrastructure`, etc. | Users only |
| `Purpose` | `Development`, `Infrastructure`, `ServiceRole` | Groups and Roles |

### S3 Bucket Naming Patterns

| Pattern | Purpose | Access |
|---------|---------|--------|
| `technova-dados-*` | Development data | Developers (read), Interns (read) |
| `technova-app-data-*` | Application data | EC2 instances via service role (read/write) |

## Error Handling

### Terraform Validation

**Strategy**: Use Terraform's built-in validation before applying changes.

**Commands**:
```bash
# Format code
terraform fmt -recursive

# Validate syntax and configuration
terraform validate

# Preview changes
terraform plan
```

**Expected Behavior**:
- `terraform validate` must pass without errors
- `terraform plan` must show expected resource creation
- No warnings about deprecated syntax or configurations

### IAM Policy Validation

**Strategy**: Test policies using AWS IAM Policy Simulator or actual resource access.

**Validation Steps**:
1. Create test S3 buckets (`technova-dados-test`, `technova-app-data-test`)
2. Create test EC2 instance with `Project=TechNova` tag
3. Use AWS CloudShell or CLI with user credentials to test permissions
4. Verify deny statements prevent unauthorized actions

**Expected Behavior**:
- Developers can read from `technova-dados-*` buckets
- Platform engineers can manage tagged EC2 instances only
- Interns cannot perform destructive actions (explicit deny works)
- EC2 role can read/write to `technova-app-data-*` buckets

### Error Scenarios

| Error | Cause | Resolution |
|-------|-------|------------|
| Resource already exists | User/group/policy name conflicts | Change resource names or import existing resources |
| Insufficient IAM permissions | Terraform executor lacks IAM permissions | Grant IAM admin permissions to Terraform executor |
| Invalid policy document | Syntax error in policy JSON | Use `aws_iam_policy_document` data source (type-safe) |
| Circular dependency | Resource references create cycle | Review resource dependencies, reorder definitions |

## Testing Strategy

Since this is Infrastructure as Code (IaC), property-based testing is not applicable. Instead, we use:

### 1. Terraform Validation Tests

**Purpose**: Ensure Terraform syntax and configuration are correct.

**Tests**:
- `terraform fmt -check`: Verify code formatting
- `terraform validate`: Check syntax and configuration validity
- `terraform plan`: Preview resource changes

**Success Criteria**:
- All commands pass without errors
- Plan shows expected resource creation (3 users, 3 groups, 3 policies, 1 role, 1 instance profile)

### 2. Policy Syntax Tests

**Purpose**: Validate IAM policy documents are syntactically correct.

**Tests**:
- Use `aws_iam_policy_document` data source (provides type checking)
- Review generated JSON with `terraform show -json`

**Success Criteria**:
- Policy documents are valid JSON
- Actions, resources, and conditions follow AWS IAM syntax
- No deprecated or invalid actions

### 3. Compliance Tests

**Purpose**: Verify security requirements are met.

**Tests**:
- **No Hardcoded Credentials**: Search codebase for patterns `AKIA*`, `aws_access_key_id`, `aws_secret_access_key`
- **Least Privilege**: Review each policy to ensure minimal required permissions
- **Explicit Denies**: Verify intern policy contains deny statements
- **Tag Coverage**: Ensure all resources have required tags

**Success Criteria**:
- No credentials found in code
- Each policy grants only required actions
- Intern policy includes explicit deny statement
- All resources tagged with `Project`, `ManagedBy`, and appropriate additional tags

### 4. Integration Tests (Manual)

**Purpose**: Verify policies work as expected in AWS environment.

**Tests**:
1. **Developer Access Test**:
   - Create S3 bucket: `technova-dados-test`
   - Assume developer user credentials
   - Attempt `s3:GetObject` (should succeed)
   - Attempt `s3:PutObject` (should fail)

2. **Platform Engineer Access Test**:
   - Create EC2 instance with `Project=TechNova` tag
   - Create EC2 instance without tag
   - Assume platform engineer credentials
   - Attempt to stop tagged instance (should succeed)
   - Attempt to stop untagged instance (should fail)

3. **Intern Restriction Test**:
   - Assume intern user credentials
   - Attempt `s3:GetObject` (should succeed)
   - Attempt `s3:DeleteObject` (should fail - explicit deny)
   - Attempt `ec2:DescribeInstances` (should succeed)
   - Attempt `ec2:StopInstances` (should fail - explicit deny)

4. **EC2 Role Test**:
   - Launch EC2 instance with `technova-ec2-s3-instance-profile`
   - From instance, attempt S3 operations on `technova-app-data-test` bucket
   - Verify read/write operations succeed
   - Verify temporary credentials are used (no hardcoded keys)

**Success Criteria**:
- All expected allow operations succeed
- All expected deny operations fail
- No manual credential configuration needed for EC2

### 5. Snapshot Tests

**Purpose**: Capture and compare Terraform plan output to detect unintended changes.

**Process**:
1. Generate initial plan: `terraform plan -out=plan.tfplan`
2. Save plan as baseline: `terraform show -json plan.tfplan > baseline.json`
3. On subsequent changes, compare new plan to baseline
4. Review any differences for unintended modifications

**Success Criteria**:
- Changes match expected modifications
- No unexpected resource deletions or replacements
- Tags remain consistent across all resources

## Security Considerations

### 1. No Hardcoded Credentials
- Terraform code contains no AWS access keys or secret keys
- Authentication via AWS CLI profiles, environment variables, or instance roles
- EC2 instances use IAM roles (temporary credentials) instead of embedded keys

### 2. Least Privilege Implementation
- Developer policy: read-only S3 access to specific bucket pattern
- Platform engineer policy: conditional EC2 management (tagged instances only)
- Intern policy: read-only access with explicit denies on destructive actions

### 3. Explicit Deny Strategy
- Intern policy uses `Effect: "Deny"` for destructive actions
- Deny statements take precedence over allow statements in IAM evaluation
- Protects against privilege escalation via other policy attachments

### 4. Conditional Access
- Platform engineer policy uses `Condition` block to restrict EC2 management
- Only instances tagged with `Project=TechNova` can be managed
- Enforces resource boundaries and prevents accidental modifications

### 5. Service Role Best Practice
- EC2 instances use IAM roles via instance profiles
- Credentials automatically rotated by AWS (temporary security tokens)
- No need to distribute or manage long-term credentials

### 6. Audit and Traceability
- All resources tagged with `Project` and `ManagedBy` for ownership tracking
- IAM policy statements include `Sid` for CloudTrail identification
- Outputs provide resource ARNs for audit and compliance reporting

## Dependencies

### Required Tools
- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **AWS CLI**: For authentication and manual testing
- **Valid AWS Credentials**: IAM permissions to create/manage IAM resources

### AWS Permissions Required
The Terraform executor needs these IAM permissions:
- `iam:CreateUser`
- `iam:CreateGroup`
- `iam:CreatePolicy`
- `iam:CreateRole`
- `iam:CreateInstanceProfile`
- `iam:AttachGroupPolicy`
- `iam:AddUserToGroup`
- `iam:TagUser`, `iam:TagGroup`, `iam:TagPolicy`, `iam:TagRole`
- `iam:Get*` and `iam:List*` for read operations

### Region
- **Target Region**: `us-east-1` (specified in providers.tf)

## Implementation Notes

### Terraform Best Practices Applied
1. **Type-Safe Policy Generation**: Use `aws_iam_policy_document` data source instead of raw JSON
2. **DRY Principle**: Avoid repetition by using data sources and references
3. **Explicit Dependencies**: Terraform automatically resolves dependencies via resource references
4. **Consistent Naming**: Follow naming conventions for all resources
5. **Meaningful Outputs**: Provide useful information after apply

### Future Enhancements (Out of Scope)
- MFA enforcement for users
- Password policy configuration
- Access key rotation policies
- CloudTrail logging for IAM events
- Cost allocation tags
- Cross-account role assumptions
- SSO integration

---

**Design Version**: 1.0  
**Last Updated**: 2025-01-XX  
**Status**: Ready for Implementation
