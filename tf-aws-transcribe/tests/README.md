# tf-aws-transcribe — Test Suite

## Structure

```
tests/
├── unit/
│   ├── defaults.tftest.hcl      # Default values, gate behaviour, BYO role, tag merging
│   └── validation.tftest.hcl    # Variable validation rules (expect_failures)
└── integration/
    └── basic.tftest.hcl         # Real AWS — vocabulary creation, BYO role, filters
```

## Running unit tests (no AWS credentials required)

Unit tests use mock provider credentials and run plan-only, so they never touch AWS.

```bash
cd tf-aws-transcribe
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl

# Or run the entire unit suite at once
terraform test -filter=tests/unit
```

## Running integration tests (real AWS required)

> **SKIP_IN_CI** — these tests create real AWS resources and require valid credentials.

Prerequisites:
- AWS credentials configured (environment variables, `~/.aws/credentials`, or an IAM instance profile)
- The target region (`us-east-1` by default) must have Amazon Transcribe available
- The IAM principal running the tests must have permissions to create Transcribe vocabularies and IAM roles

```bash
cd tf-aws-transcribe

# Use real credentials
export AWS_REGION=us-east-1
terraform test -filter=tests/integration/basic.tftest.hcl
```

Terraform test automatically destroys resources created by `command = apply` runs after each run block completes.

## Test philosophy

| Layer       | Goal                                                              | AWS calls? |
|-------------|-------------------------------------------------------------------|------------|
| unit        | Validate plan-time logic: gates, defaults, name_prefix, tags      | No         |
| validation  | Confirm `validation {}` blocks reject bad inputs via plan failure | No         |
| integration | End-to-end resource creation and output correctness               | Yes        |
