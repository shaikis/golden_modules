# Tests — tf-aws-data-e-datasync

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

- **`unit/defaults.tftest.hcl`** — Verifies feature gates default to `false`, BYO IAM/KMS
- **`unit/validation.tftest.hcl`** — Verifies variable validation rules
- **`integration/basic.tftest.hcl`** — Creates minimal resources, checks outputs, destroys

## BYO Foundational Pattern

- `role_arn` — from `tf-aws-iam` (null = auto-create via `create_iam_role = true`)
- `kms_key_arn` — from `tf-aws-kms` (null = no encryption)
