# Tests — tf-aws-amp

This directory contains automated tests for the `tf-aws-amp` module using the native Terraform test framework (`terraform test`, available in Terraform >= 1.6).

---

## Directory Layout

```
tests/
├── unit/
│   ├── defaults.tftest.hcl     # Validates default variable values and resource defaults
│   └── validation.tftest.hcl   # Validates custom input combinations via plan assertions
└── README.md
```

---

## Unit Tests (`tests/unit/`)

Unit tests run exclusively with `command = plan` — they never call the AWS API and require no real credentials or infrastructure. They validate:

- Default variable values are set correctly (e.g. `enable_alert_manager = false`).
- Computed locals resolve as expected (e.g. workspace alias falls back to `name`).
- Custom inputs override defaults correctly (e.g. `workspace_alias`).
- Feature flags (`create_irsa_role`, `create_managed_scraper`) gate resource creation.

**Run unit tests:**

```bash
cd tf-aws-amp
terraform test --filter=tests/unit
```

Because these tests only plan, they complete in seconds and do not require AWS credentials beyond what Terraform needs to resolve provider schemas.

---

## Integration Tests

Integration tests (not included in this repository by default) use `command = apply` to provision real AWS resources and assert on live state. They are typically placed under `tests/integration/` and should be run in an isolated AWS account or with a short-lived sandbox role.

A typical integration test pattern for this module:

```hcl
# tests/integration/basic.tftest.hcl
variables {
  name        = "ci-amp-test"
  environment = "ci"
}

run "creates_workspace" {
  command = apply

  assert {
    condition     = length(output.workspace_id) > 0
    error_message = "Workspace ID should be non-empty after apply."
  }
}
```

**Prerequisites for integration tests:**

- Valid AWS credentials with permissions to create AMP workspaces, IAM roles, and CloudWatch log groups.
- A dedicated test AWS account or sandbox environment to avoid polluting production state.
- Run `terraform test` (without `--filter`) or `terraform test --filter=tests/integration`.

**Cleanup:** `terraform test` automatically destroys resources created during `apply` runs at the end of each test file unless `--destroy=false` is passed.

---

## Running All Tests

```bash
# Unit tests only (no AWS credentials needed for plan assertions)
terraform test --filter=tests/unit

# All tests including integration (requires AWS credentials)
terraform test
```
