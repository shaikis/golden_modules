# Integration tests — tf-aws-lambda
# Cost estimate: $0.00 — Lambda free tier covers 1M requests and 400,000 GB-seconds/month.
# These tests CREATE a real Lambda function using an inline Python 3.12 handler
# embedded as a base64-encoded zip. No S3 bucket or pre-built artifact required.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create a minimal Python 3.12 Lambda function ────────────────────
# SKIP_IN_CI
run "create_python312_lambda" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    function_name = "tftest-lambda-basic"
    description   = "Integration test — minimal Python 3.12 handler"
    runtime       = "python3.12"
    handler       = "index.handler"
    architectures = ["x86_64"]
    package_type  = "Zip"
    # Minimal valid zip: a zip file containing index.py with a handler function.
    # Generated with: zip -j /tmp/fn.zip index.py && base64 /tmp/fn.zip
    # index.py content: def handler(event, context): return {"statusCode": 200}
    filename      = "${path.module}/fixtures/index.zip"
    memory_size   = 128
    timeout       = 10
    publish       = true
    environment   = "test"
  }

  assert {
    condition     = length(output.function_arn) > 0
    error_message = "function_arn must be non-empty."
  }

  assert {
    condition     = startswith(output.function_arn, "arn:aws:lambda:")
    error_message = "function_arn must start with 'arn:aws:lambda:'."
  }

  assert {
    condition     = length(output.function_name) > 0
    error_message = "function_name must be non-empty."
  }

  assert {
    condition     = length(output.log_group_name) > 0
    error_message = "log_group_name must be non-empty."
  }
}

# ── Test 2: Create Lambda with environment variables ─────────────────────────
# SKIP_IN_CI
run "create_lambda_with_env_vars" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    function_name = "tftest-lambda-envvars"
    runtime       = "python3.12"
    handler       = "index.handler"
    package_type  = "Zip"
    filename      = "${path.module}/fixtures/index.zip"
    environment_variables = {
      APP_ENV = "test"
      LOG_LEVEL = "INFO"
    }
    environment = "test"
  }

  assert {
    condition     = startswith(output.function_arn, "arn:aws:lambda:")
    error_message = "function_arn must start with 'arn:aws:lambda:'."
  }
}
