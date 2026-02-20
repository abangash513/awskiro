# AWS Resource Access Control with ABAC (Attribute-Based Access Control)

This document describes NXOP's implementation of Attribute-Based Access Control (ABAC) for AWS resource access using resource tags. This approach provides flexible, scalable, and maintainable access control for developers across NXOP environments. ABAC is currently implemented for S3 buckets and AWS Secrets Manager secrets. At this time, there is only a single `NXOPDeveloper` role, but more roles will likely be added in the future as additional personas and requirements are identified.

## Overview

ABAC lets you control access to AWS resources based on tags you attach to those resources. Instead of hardcoding resource names or ARN patterns in IAM policies, you can use tags to control who gets access. This approach is currently used for S3 buckets and AWS Secrets Manager secrets, allowing different levels of access (read-only, read-write, or read-write-delete for S3; read-only or read-write for Secrets Manager) just by tagging resources. No IAM policy changes needed.

## Why ABAC

### Previous Approach: Naming Convention Pattern

Before implementing ABAC, the `NXOPDeveloper` permission set granted access to AWS resources based on naming patterns. For example, S3 access was based on bucket naming patterns:

```json
{
  "Sid": "S3ReadWriteAccess",
  "Effect": "Allow",
  "Action": "s3:*Object",
  "Resource": "arn:aws:s3:::*fxip/*"
}
```

And Secrets Manager access was based on secret path patterns:

```json
{
  "Sid": "SecretsManagerAccess",
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue",
    "secretsmanager:PutSecretValue"
  ],
  "Resource": [
    "arn:aws:secretsmanager:*:*:secret:/fxip/*",
    "arn:aws:secretsmanager:*:*:secret:/nxop/*"
  ]
}
```

This approach had several limitations:

- **Inflexible**: Every resource matching the naming pattern got the same level of access, whether it needed it or not
- **Not scalable**: Adding new resource patterns meant updating IAM policies every time
- **Coarse-grained**: There was no way to differentiate between read-only and read-write permissions for the same resource type
- **Maintenance burden**: Many access change scenarios required involving the GaaS team

### New Approach: Tag-Based ABAC

With ABAC, access is determined by tags applied to AWS resources. Here's what that looks like for S3:

```json
{
  "Sid": "S3ABACS3ReadWriteAccess",
  "Action": ["s3:ListBucket", "s3:GetObject", "s3:PutObject"],
  "Effect": "Allow",
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/nxopdeveloper": "readwrite",
      "aws:ResourceAccount": ["178549792225", "972818039298"]
    }
  }
}
```

## Benefits of ABAC

### Flexibility
- You can grant different access levels to different buckets without touching policy code
- Adjusting access is as simple as changing a tag value
- One policy framework supports multiple services and use cases

### Scalability
- New resources don't require IAM policy updates
- The approach works just as well for hundreds or thousands of resources
- Naming conventions are no longer a constraint

### Fine-Grained Control
- Three distinct access levels let you match permissions to actual needs
- Each bucket gets only the minimum necessary permissions
- Access patterns are easy to audit and understand

### Reduced Operational Overhead
- The infrastructure team manages resource access through tags
- Routine access changes don't need GaaS team involvement
- Teams can iterate and deploy faster

### Security
- Resources without tags are automatically inaccessible (opt-in by default)
- Access levels are clearly separated
- It's easy to see which resources grant which permissions

## Tagging Strategy

### Tag Key

The tag key comes from the IAM permission set name, converted to lowercase:

**Tag Key**: `nxopdeveloper`

This creates a clear connection between the tag and the permission set that uses it. It also helps avoid conflicts with other tagging schemes.

### Tag Values for S3

For S3 buckets, three access levels are supported:

| Tag Value | Permissions | Use Case |
|-----------|-------------|----------|
| `readonly` | `s3:ListBucket`<br>`s3:GetObject` | Buckets where developers require view or download access but not modification capabilities |
| `readwrite` | `s3:ListBucket`<br>`s3:GetObject`<br>`s3:PutObject` | Buckets where developers require upload and modification capabilities but not deletion |
| `readwritedelete` | `s3:ListBucket`<br>`s3:GetObject`<br>`s3:PutObject`<br>`s3:DeleteObject` | Buckets where developers require full control including deletion capabilities |

**Note**: This ABAC approach can easily be expanded to additional human access roles as needed by defining new tag keys based on permission set names.

### Tag Values for Secrets Manager

For AWS Secrets Manager secrets, two access levels are supported:

| Tag Value | Permissions | Use Case |
|-----------|-------------|----------|
| `readonly` | `secretsmanager:GetSecretValue`<br>`secretsmanager:DescribeSecret`<br>`secretsmanager:ListSecretVersionIds` | Secrets where developers require read access but not modification capabilities |
| `readwrite` | `secretsmanager:GetSecretValue`<br>`secretsmanager:DescribeSecret`<br>`secretsmanager:ListSecretVersionIds`<br>`secretsmanager:PutSecretValue`<br>`secretsmanager:UpdateSecret` | Secrets where developers require both read and update capabilities |

### Tagging Examples

**S3 Bucket:**

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "nxop-fxip-data-dev"
  
  tags = {
    nxopdeveloper = "readwrite"
  }
}
```

**Secrets Manager Secret:**

```hcl
resource "aws_secretsmanager_secret" "example" {
  name = "/nxop/database/credentials"
  
  tags = {
    nxopdeveloper = "readonly"
  }
}
```

**Important**: S3 buckets require ABAC to be explicitly enabled. Buckets without ABAC enabled will not work with tag-based access control policies, even if they have the appropriate tags. Secrets Manager secrets support tagging natively and do not require additional enablement.

## Security Considerations

### Account Restriction

All ABAC policies include an `aws:ResourceAccount` condition that locks down access to specific NXOP accounts:
- Dev: `178549792225`
- Nonprod: `972818039298`

This prevents cross-account access, even if a resource in another account happens to have the same tag and has a resource-based policy that would allow access.

### Default Deny

Resources without the `nxopdeveloper` tag are automatically off-limits to the `NXOPDeveloper` role. This opt-in model ensures access is always intentional.

### Unrecognized Tag Values

If a resource has an unrecognized tag value (like `nxopdeveloper = "invalid"`), access will be denied since it doesn't match any policy conditions.

## Managing Resource Access

### S3 Buckets

#### To Grant Access to a New Bucket

1. Enable ABAC on the bucket:
   ```hcl
   resource "aws_s3_bucket_abac" "new_bucket" {
     bucket = aws_s3_bucket.new_bucket.id
   }
   ```

2. Add the appropriate tag:
   ```hcl
   resource "aws_s3_bucket" "new_bucket" {
     bucket = "nxop-new-bucket"
     
     tags = {
       nxopdeveloper = "readwrite"
     }
   }
   ```

3. Apply the Terraform changes. That's it! No IAM policy changes needed.

#### To Change Access Level

Just update the tag value:

```hcl
tags = {
  nxopdeveloper = "readonly"  # Changed from readwrite
}
```

#### To Revoke Access

Remove the tag entirely, or set it to an unrecognized yet descriptive value:

```hcl
tags = {
  nxopdeveloper = "none"  # Or just remove the tag
}
```

### Secrets Manager Secrets

#### To Grant Access to a New Secret

Add the appropriate tag when creating the secret:

```hcl
resource "aws_secretsmanager_secret" "new_secret" {
  name = "/nxop/application/api-key"
  
  tags = {
    nxopdeveloper = "readonly"
  }
}
```

No additional enablement required. Apply the Terraform changes and the tag-based access will work immediately.

#### To Change Access Level

Update the tag value:

```hcl
tags = {
  nxopdeveloper = "readwrite"  # Changed from readonly
}
```

#### To Revoke Access

Remove the tag entirely, or set it to an unrecognized value:

```hcl
tags = {
  nxopdeveloper = "none"  # Or remove the tag
}
```
