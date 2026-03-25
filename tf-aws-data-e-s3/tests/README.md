# Tests — tf-aws-data-e-s3

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

- `kms_key_arn` from tf-aws-kms (`null` = AWS-managed S3 key)

## Notes

S3 integration tests fall within the AWS free tier (5 GB storage).
The integration test creates a single bucket and asserts the `bucket_arn` output is set.
