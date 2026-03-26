# tf-aws-polly — Test Suite

This directory contains the Terraform test suite for the `tf-aws-polly` module,
using the native `terraform test` framework (requires Terraform >= 1.6).

## Structure

```
tests/
├── README.md               # this file
├── unit/
│   ├── defaults.tftest.hcl     # default variable values and feature-gate behaviour
│   └── validation.tftest.hcl  # input validation and edge cases
└── integration/
    └── basic.tftest.hcl        # real AWS resources (skipped in CI by default)
```

## Running the tests

### Unit tests (no AWS credentials required — plan only)

```bash
# From the module root
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl

# Or run all unit tests at once
terraform test -filter=tests/unit
```

### Integration tests (requires AWS credentials)

> **Warning**: Integration tests create real AWS resources.
> Polly lexicons are free, but you must have appropriate IAM permissions.

```bash
terraform test -filter=tests/integration/basic.tftest.hcl
```

## Environment variables

| Variable | Purpose |
|---|---|
| `AWS_REGION` | Target AWS region (default: `us-east-1`) |
| `AWS_PROFILE` | Named AWS CLI profile |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Static credentials |

## CI behaviour

Integration tests are tagged with `# SKIP_IN_CI` comments. Your CI pipeline should
run only unit tests by default:

```yaml
# Example GitHub Actions step
- name: Terraform unit tests
  run: terraform test -filter=tests/unit
```
