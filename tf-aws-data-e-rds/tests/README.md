# Tests — tf-aws-data-e-rds

Automated tests using Terraform test framework (requires Terraform >= 1.6).

## Test Types

| Folder        | Command                                      | Cost               | When to Run    |
|---------------|----------------------------------------------|--------------------|----------------|
| unit/         | terraform test -filter=tests/unit            | Free               | Every PR       |
| integration/  | terraform test -filter=tests/integration     | ~$0.017/hr (t3.micro) | Merge to main |

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

- `kms_key_arn` from tf-aws-kms (`null` = AWS-managed key)
- `backup_plan_arn` from tf-aws-backup (`null` = module-managed backup retention)

## Notes

Integration tests create a `db.t3.micro` MySQL instance and assert the `db_instance_identifier` output is set.
Remember to destroy resources after testing to avoid ongoing cost.
