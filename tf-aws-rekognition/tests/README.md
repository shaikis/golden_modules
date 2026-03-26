# Tests for tf-aws-rekognition

This directory contains Terraform native tests (`*.tftest.hcl`) organised into
two tiers:

```
tests/
├── unit/
│   ├── defaults.tftest.hcl      # All feature gates default false — plan only
│   └── validation.tftest.hcl    # Input validation rules — plan only (expect failures)
└── integration/
    └── basic.tftest.hcl         # Apply one collection, assert output — SKIP_IN_CI
```

---

## Running unit tests (no AWS credentials required)

```bash
terraform test -filter=tests/unit/defaults.tftest.hcl
terraform test -filter=tests/unit/validation.tftest.hcl
```

Or run both together:

```bash
terraform test -filter=tests/unit
```

---

## Running integration tests (live AWS account required)

> **Warning:** The integration test provisions real AWS resources in the
> configured account and region. Estimated cost: $0 (Rekognition collections
> have no idle charge). Resources are destroyed automatically after the test run.

```bash
# Ensure credentials are exported, then:
terraform test -filter=tests/integration/basic.tftest.hcl
```

In CI pipelines that should skip live tests, check for the `# SKIP_IN_CI`
marker in the file and conditionally omit the `-filter` argument, or guard
execution behind an environment variable:

```bash
[ "${SKIP_INTEGRATION:-false}" = "true" ] || \
  terraform test -filter=tests/integration/basic.tftest.hcl
```

---

## Test matrix

| File | Command | Needs AWS | Description |
|---|---|---|---|
| `unit/defaults.tftest.hcl` | plan | No | Verifies all gates default false, no resources planned |
| `unit/validation.tftest.hcl` | plan | No | Verifies `validation` blocks reject bad inputs |
| `integration/basic.tftest.hcl` | apply | Yes | Creates a real collection; asserts output |
