# tf-aws-comprehend — Tests

This directory contains Terraform native tests (`*.tftest.hcl`) for the
`tf-aws-comprehend` module. Tests are organised into two tiers.

## Test tiers

### unit/

Plan-only tests that run entirely locally without AWS credentials.
They validate default values, variable constraints, and plan-time logic.

```
tests/unit/
├── defaults.tftest.hcl     # Verify all feature-gate defaults
└── validation.tftest.hcl   # Verify input validation rules reject bad values
```

Run with:

```bash
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl
# or both at once:
terraform test -filter=tests/unit/
```

### integration/

Plan-only tests that exercise realistic module configurations.
They do NOT apply resources (Comprehend training is $3+/hour and takes
30–90 minutes), but they validate that `terraform plan` produces a correct,
error-free configuration.

```
tests/integration/
└── basic.tftest.hcl   # Plan-only end-to-end test (SKIP_IN_CI when running apply)
```

Run with:

```bash
terraform test -filter=tests/integration/basic.tftest.hcl
```

## Prerequisites

- Terraform >= 1.3.0
- AWS provider >= 5.0
- For unit tests: no AWS credentials required (plan only, mocked provider)
- For integration tests: valid AWS credentials are recommended so the plan
  can resolve IAM/KMS data sources accurately, but `terraform plan` itself
  does not create any billable resources.

## CI guidance

In CI pipelines:
- **Always run** `tests/unit/` — fast, free, no credentials needed.
- **Run** `tests/integration/` with `command = plan` only — validates the
  configuration without incurring AWS costs.
- **Never run** `terraform apply` in CI for Comprehend resources unless your
  pipeline explicitly accounts for the $3+/hour training cost and 30–90 min
  wait time.
