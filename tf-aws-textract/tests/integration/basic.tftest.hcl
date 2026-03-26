# Integration test — real AWS apply
# SKIP_IN_CI: requires AWS credentials and creates real (but free-tier) resources
#
# Cost note:
#   - SNS topics: no standing cost, charged only per message published
#   - SQS queues: first 1M requests/month free; no standing cost
#   - Textract API calls: pay-per-page; this test makes ZERO Textract API calls
#   - All resources are destroyed immediately after assertions pass
#
# Run manually:
#   export AWS_PROFILE=test-account
#   export AWS_REGION=us-east-1
#   terraform test -filter=tests/integration/basic.tftest.hcl

provider "aws" {
  # Region can be overridden via AWS_REGION env variable
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 1: Create one SNS topic + one SQS queue, assert outputs have 1 entry each
# ──────────────────────────────────────────────────────────────────────────────
run "basic_sns_and_sqs_creation" {
  command = apply

  variables {
    name_prefix = "tftest-textract"

    # IAM
    create_iam_role = true

    # One SNS topic for async job notifications
    create_sns_topics = true
    sns_topics = {
      jobs = {
        display_name = "Textract Integration Test Topic"
      }
    }

    # One SQS queue with DLQ for result processing
    create_sqs_queues = true
    sqs_queues = {
      results = {
        visibility_timeout_seconds = 300
        message_retention_seconds  = 3600 # 1 hour — short for test cleanup
        create_dlq                 = true
      }
    }

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
      Purpose     = "tf-aws-textract integration test"
    }
  }

  # ── SNS assertions ──────────────────────────────────────────────────────────

  assert {
    condition     = length(output.sns_topic_arns) == 1
    error_message = "Expected exactly 1 entry in sns_topic_arns output map."
  }

  assert {
    condition     = contains(keys(output.sns_topic_arns), "jobs")
    error_message = "Expected sns_topic_arns to contain key 'jobs'."
  }

  assert {
    condition     = can(regex("^arn:aws:sns:", output.sns_topic_arns["jobs"]))
    error_message = "SNS topic ARN for 'jobs' does not look like a valid SNS ARN."
  }

  # ── SQS assertions ──────────────────────────────────────────────────────────

  assert {
    condition     = length(output.sqs_queue_urls) == 1
    error_message = "Expected exactly 1 entry in sqs_queue_urls output map."
  }

  assert {
    condition     = contains(keys(output.sqs_queue_urls), "results")
    error_message = "Expected sqs_queue_urls to contain key 'results'."
  }

  assert {
    condition     = can(regex("^https://sqs\\.", output.sqs_queue_urls["results"]))
    error_message = "SQS queue URL for 'results' does not look like a valid SQS URL."
  }

  assert {
    condition     = length(output.sqs_queue_arns) == 1
    error_message = "Expected exactly 1 entry in sqs_queue_arns output map."
  }

  assert {
    condition     = can(regex("^arn:aws:sqs:", output.sqs_queue_arns["results"]))
    error_message = "SQS queue ARN for 'results' does not look like a valid SQS ARN."
  }

  # ── DLQ assertions ──────────────────────────────────────────────────────────

  assert {
    condition     = length(output.sqs_dlq_arns) == 1
    error_message = "Expected exactly 1 entry in sqs_dlq_arns output map (create_dlq = true for 'results')."
  }

  assert {
    condition     = contains(keys(output.sqs_dlq_arns), "results")
    error_message = "Expected sqs_dlq_arns to contain key 'results'."
  }

  assert {
    condition     = can(regex("^arn:aws:sqs:", output.sqs_dlq_arns["results"]))
    error_message = "DLQ ARN for 'results' does not look like a valid SQS ARN."
  }

  # ── IAM assertions ──────────────────────────────────────────────────────────

  assert {
    condition     = can(regex("^arn:aws:iam:", output.iam_role_arn))
    error_message = "iam_role_arn does not look like a valid IAM ARN."
  }

  assert {
    condition     = output.iam_role_name != ""
    error_message = "iam_role_name should be non-empty when create_iam_role = true."
  }

  assert {
    condition     = can(regex("^arn:aws:iam:", output.iam_service_role_arn))
    error_message = "iam_service_role_arn does not look like a valid IAM ARN."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Test 2: Verify BYO role pattern — no IAM resources created when role_arn supplied
# ──────────────────────────────────────────────────────────────────────────────
run "byo_role_outputs_passthrough" {
  command = apply

  variables {
    name_prefix     = "tftest-textract-byo"
    create_iam_role = false
    # Use the role created in the previous run as BYO
    role_arn = run.basic_sns_and_sqs_creation.iam_role_arn

    create_sns_topics = true
    sns_topics = {
      async = {}
    }
  }

  assert {
    condition     = output.iam_role_arn == run.basic_sns_and_sqs_creation.iam_role_arn
    error_message = "When create_iam_role = false, iam_role_arn output should equal the provided role_arn."
  }

  assert {
    condition     = output.iam_role_name == ""
    error_message = "iam_role_name should be empty string when create_iam_role = false."
  }

  assert {
    condition     = length(output.sns_topic_arns) == 1
    error_message = "Expected 1 SNS topic in BYO role test."
  }
}
