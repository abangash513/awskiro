# Lessons Learned: AWS IAM Identity Center Inline Policy Behavior

## What Happened

On December 16, 2025, an issue occurred with the `NXOPDeveloper` permission set used in the NXOP Dev and Nonprod environments. Between 2:31 PM and 3:13 PM CT, developers temporarily lost some permissions. The Terraform plan that was output by the associated workflow in the `AAInternal/aws-aft-account-customizations` repo was misleading and gave a false sense of security about how AWS IAM Identity Center handles inline policies.

## The Issue

The goal was to add attribute-based access control (ABAC) permissions for S3 to the NXOPDeveloper permission set. To accomplish this, a second `aws_ssoadmin_permission_set_inline_policy` resource was added to the Terraform configuration ([PR #153](https://github.com/AAInternal/aws-aft-account-customizations/pull/153)).

This approach failed because AWS IAM Identity Center only supports a single inline policy per permission set. When Terraform applied the changes, it replaced the existing policy (which contained CloudShell, Secrets Manager, KMS, MSK, and MSF permissions) with the new ABAC policy. Developers temporarily lost access to the permissions in the original policy.

## Contributing Factors

The Terraform plan output was misleading. It showed:

```
Plan: 1 to add, 1 to change, 0 to destroy.
```

The plan indicated it would *create* the new `s3_abac_access_policy_dev` resource but didn't clearly show that the existing inline policy would be replaced. This is a known limitation of how Terraform handles AWS SSO inline policies. Only one can exist per permission set, so adding a second one silently removes the first.

## The Fix

The issue was quickly resolved by consolidating both policies into a single `aws_ssoadmin_permission_set_inline_policy` resource ([PR #155](https://github.com/AAInternal/aws-aft-account-customizations/pull/155)).

However, when the AFT pipeline ran with the fix, another problem occurred. Terraform tried to destroy the second policy and update the first simultaneously, which caused this error:

```
Error: Provider produced inconsistent result after apply

When applying changes to
aws_ssoadmin_permission_set_inline_policy.custom_cloudshell_policy_dev,
provider "provider[\"registry.terraform.io/hashicorp/aws\"]" produced an
unexpected new value: Root resource was present, but now absent.
```

This left the permission set in a state where all custom inline policies were deleted. The GaaS team manually re-executed the AFT pipeline, which successfully applied the consolidated policy and restored all permissions.

## Key Takeaways

1. **AWS IAM Identity Center limitation**: Only one inline policy is allowed per permission set. Multiple policy statements must be combined into a single policy document.

2. **Terraform plan limitations**: The plan output doesn't make it obvious when an inline policy will be replaced rather than added. The `+` for a new resource doesn't tell the whole story when it comes to SSO inline policies.

3. **Development and nonprod environment impact**: While this occurred in development and nonprod environments, it serves as a reminder that changes to shared resources can affect active development work.

## Going Forward

- When adding permissions to an existing permission set with an inline policy, merge them into the existing policy rather than creating a new resource
- Exercise additional care when reviewing Terraform plans for SSO resources, as they can have non-intuitive behaviors
- Consider refactoring permission sets to use individual policies and policy attachments
