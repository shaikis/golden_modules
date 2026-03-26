# Tests — tf-aws-sagemaker

This directory contains Terraform native tests (`.tftest.hcl`) organised into `unit/` and `integration/` suites.

Run all tests from the module root:

```bash
terraform test
```

Run a specific suite:

```bash
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl
terraform test -filter=tests/integration/basic.tftest.hcl
```

---

## Test Inventory

| Suite | File | Type | AWS Required | Description |
|-------|------|------|--------------|-------------|
| unit | `unit/defaults.tftest.hcl` | plan-only | No | Verifies feature gate defaults, BYO role pattern, name_prefix application, and tag merging. |
| unit | `unit/validation.tftest.hcl` | plan-only (expect_failures) | No | Confirms input validation rules reject bad values for auth_mode, instance_type format, and feature_type. |
| integration | `integration/basic.tftest.hcl` | apply | Yes | Creates only the SageMaker IAM role (free-tier safe) and asserts the `iam_role_arn` output is non-empty. |

---

## Unit Tests

Unit tests run with `command = plan` and never create real AWS resources. They are safe to run in CI without credentials that have write access.

### `defaults.tftest.hcl`

- All `create_X` gates default to `false`.
- `create_iam_role` defaults to `true`.
- BYO role pattern: `create_iam_role = false` + `role_arn` supplied → `local.role_arn` resolves to supplied ARN.
- `name_prefix` is applied to resource names with a trailing dash separator.
- Module-level `tags` are merged into every resource alongside the mandatory `ManagedBy` and `Module` stamps.

### `validation.tftest.hcl`

- Invalid `auth_mode` (not `IAM` or `SSO`) on a domain → plan fails with validation error.
- `instance_type` that does not start with `ml.` on a notebook → plan fails with validation error.
- Invalid `feature_type` (not `Integral`, `Fractional`, or `String`) on a feature group feature → plan fails with validation error.

---

## Integration Tests

Integration tests use `command = apply` and require valid AWS credentials with appropriate permissions.

> **CI Note**: Integration tests are marked `# SKIP_IN_CI` in their files. Configure your CI pipeline to skip the `integration/` directory unless running against a dedicated sandbox account.

### `integration/basic.tftest.hcl`

- Creates the SageMaker IAM execution role only (`create_iam_role = true`, all other gates `false`).
- IAM role creation is included in the AWS Free Tier and incurs no cost.
- Asserts that `iam_role_arn` output is a non-empty string.
- Cleans up all resources in the `teardown` block via `destroy`.
