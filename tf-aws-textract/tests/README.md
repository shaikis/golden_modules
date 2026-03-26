# tf-aws-textract Tests

This directory contains Terraform native tests (`*.tftest.hcl`) organized into unit and integration suites.

## Structure

```
tests/
├── unit/
│   ├── defaults.tftest.hcl     # Feature gate defaults, BYO patterns, empty maps
│   └── validation.tftest.hcl   # Variable validation rules
└── integration/
    └── basic.tftest.hcl        # Real AWS apply: SNS + SQS creation and output assertions
```

## Running Tests

### Unit tests (no AWS credentials required — plan only)

```bash
# From the module root
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl

# Run all unit tests
terraform test -filter=tests/unit
```

### Integration tests (requires AWS credentials)

```bash
# Ensure AWS credentials are configured
export AWS_PROFILE=my-test-profile
export AWS_REGION=us-east-1

terraform test -filter=tests/integration/basic.tftest.hcl
```

> **Cost note:** SNS topics and SQS queues have no standing cost. The integration test creates one of each and destroys them immediately after assertions. Textract API calls are pay-per-page — this test makes no Textract API calls.

## CI/CD

Unit tests run on every pull request (plan only, no credentials needed).

Integration tests are skipped in CI by default (marked with `# SKIP_IN_CI`). Run them manually in a dedicated test AWS account before merging significant changes.
