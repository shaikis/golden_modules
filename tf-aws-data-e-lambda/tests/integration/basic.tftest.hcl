# Integration test — basic Lambda function creation for tf-aws-data-e-lambda
# command = apply: creates a real Lambda function in AWS.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"
#   A deployment zip must exist at the path referenced by `filename`, OR
#   remove `filename` and supply an S3 source instead.
#
# Cost: Lambda free tier covers 1M requests/month — integration tests are
# effectively free for normal usage.

# Provider configuration for the integration environment.
provider "aws" {
  region = "us-east-1"
}

run "create_python312_function" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    function_name = "integ-lambda-test-python312"
    description   = "Integration test Lambda — safe to delete"
    environment   = "test"

    runtime = "python3.12"
    handler = "index.handler"

    # Inline handler supplied via the s3 source or a pre-built zip.
    # For a quick smoke test supply a minimal zip via s3_bucket/s3_key,
    # or create a zip locally:
    #   zip /tmp/lambda_test.zip index.py
    # filename = "/tmp/lambda_test.zip"

    memory_size = 128
    timeout     = 10
    publish     = true

    # BYO role: set create_role = false and supply an existing role ARN,
    # or leave create_role = true (default) to have the module create one.
    create_role = true

    create_cloudwatch_alarms = false
    create_function_url      = false

    tags = {
      Purpose = "integration-test"
    }
  }

  assert {
    condition     = output.function_arn != ""
    error_message = "function_arn output must be set after a successful apply."
  }
}
