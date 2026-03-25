# Tests — tf-aws-managed-prefix

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
# Unit tests only (no AWS resources created)
terraform test -filter=tests/unit

# Integration tests (creates real AWS resources — always destroys after)
terraform test -filter=tests/integration

# All tests
terraform test
```

## Test Structure

- **`unit/defaults.tftest.hcl`** — Verifies all defaults are sane, feature gates, naming conventions
- **`unit/validation.tftest.hcl`** — Verifies variable validation rules reject bad inputs
- **`integration/basic.tftest.hcl`** — Creates the minimal resource set, checks outputs, destroys
