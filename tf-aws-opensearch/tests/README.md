# Tests

This directory contains Terraform native tests (`*.tftest.hcl`) for the `tf-aws-opensearch` module.

## Structure

```
tests/
├── unit/               # Plan-only tests — no AWS credentials required
│   ├── defaults.tftest.hcl     # Validates default variable values and plan shape
│   └── validation.tftest.hcl   # Validates input variable constraints
└── README.md
```

## Unit Tests (`tests/unit/`)

Unit tests use `command = plan` and never create real AWS resources. They are safe to run in CI without credentials (using mock providers or a read-only role) and complete in seconds.

**What they cover:**
- Default variable values are correct (e.g., `create_serverless = true`, `collection_type = VECTORSEARCH`)
- Accepted enum values pass validation without error (`TIMESERIES`, `SEARCH`, `VECTORSEARCH`)
- Rejected enum values trigger the correct `error_message`

**Run unit tests:**
```bash
cd tf-aws-opensearch
terraform test tests/unit/
```

## Integration Tests

> **Warning:** Integration tests create real AWS resources and incur charges.

Integration tests use `command = apply` and provision a live OpenSearch Serverless collection in your AWS account. They are intended to run in a dedicated test account or sandbox environment.

**Estimated cost:**
- OpenSearch Serverless charges a minimum of **2 OCUs per collection** (1 indexing + 1 search).
- At **$0.12/OCU-hour**, a single collection costs approximately **$0.24/hour** while active.
- Tests that create and immediately destroy a collection typically incur less than **$0.10** per run.

**To add an integration test**, create a file such as `tests/integration/apply_serverless.tftest.hcl` with `command = apply` and a `teardown` block to destroy resources after the run.

**Run integration tests (requires AWS credentials):**
```bash
cd tf-aws-opensearch
terraform test tests/integration/
```

## Provider Configuration for Tests

Tests inherit the provider from the root module. Set credentials via environment variables before running:

```bash
export AWS_REGION=us-east-1
export AWS_PROFILE=my-sandbox-profile
terraform test
```
