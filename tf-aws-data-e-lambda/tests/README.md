# Tests — tf-aws-data-e-lambda

Automated tests using Terraform test framework (requires Terraform >= 1.6).

## Test Types

| Folder        | Command                                      | Cost        | When to Run    |
|---------------|----------------------------------------------|-------------|----------------|
| unit/         | terraform test -filter=tests/unit            | Free        | Every PR       |
| integration/  | terraform test -filter=tests/integration     | Costs money | Merge to main  |

## Prerequisites

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

## Running

```bash
# Unit tests only (plan, no AWS resources created)
terraform test -filter=tests/unit

# Integration tests only (apply, real AWS resources)
terraform test -filter=tests/integration

# All tests
terraform test
```

## BYO Pattern

- `role_arn` from tf-aws-iam (`null` = auto-create)
- `kms_key_arn` from tf-aws-kms (`null` = no encryption)

## Notes

Lambda integration tests fall within the AWS free tier (1M requests/month).
The integration test creates a minimal Python 3.12 function with an inline handler and asserts the `function_arn` output is set.
