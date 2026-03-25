# Tests — tf-aws-data-e-emr

This directory contains automated tests using the [Terraform test framework](https://developer.hashicorp.com/terraform/language/tests) (requires Terraform ≥ 1.6).

## Test Types

| Folder | Command | Cost | When to Run |
|--------|---------|------|-------------|
| `unit/` | `terraform test -filter=tests/unit` | Free (plan only) | Every PR |
| `integration/` | `terraform test -filter=tests/integration` | Costs money | Merge to main |

## Prerequisites

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

## Running Tests

```bash
terraform test -filter=tests/unit
terraform test -filter=tests/integration
terraform test
```

## Test Structure

- **`unit/defaults.tftest.hcl`** — Verifies all feature gates default to `false`, BYO IAM/KMS pattern
- **`unit/validation.tftest.hcl`** — Verifies variable validation rules reject bad inputs
- **`integration/basic.tftest.hcl`** — Creates minimal resource set, checks outputs, destroys

## BYO Foundational Pattern

- `role_arn` — from `tf-aws-iam` (null = auto-create service role)
- `instance_profile_arn` — from `tf-aws-iam` (null = auto-create instance profile)
- `kms_key_arn` — from `tf-aws-kms` (null = no encryption)
