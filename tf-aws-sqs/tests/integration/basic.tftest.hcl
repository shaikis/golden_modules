# Integration tests — tf-aws-sqs
# Cost estimate: $0.00 — SQS standard queues have no hourly charge.
# First 1M requests/month free; $0.40 per million requests thereafter.
# These tests CREATE real SQS queues. Remember to run terraform destroy after.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create a standard SQS queue and verify outputs ──────────────────
# SKIP_IN_CI
run "create_standard_sqs_queue" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                       = "tftest-sqs-basic"
    fifo_queue                 = false
    visibility_timeout_seconds = 30
    message_retention_seconds  = 345600
    delay_seconds              = 0
    create_dlq                 = true
    environment                = "test"
  }

  assert {
    condition     = length(output.queue_url) > 0
    error_message = "queue_url must be non-empty."
  }

  assert {
    condition     = can(regex("sqs", output.queue_url))
    error_message = "queue_url must contain 'sqs'."
  }

  assert {
    condition     = length(output.queue_arn) > 0
    error_message = "queue_arn must be non-empty."
  }

  assert {
    condition     = startswith(output.queue_arn, "arn:aws:sqs:")
    error_message = "queue_arn must start with 'arn:aws:sqs:'."
  }

  assert {
    condition     = length(output.queue_name) > 0
    error_message = "queue_name must be non-empty."
  }

  assert {
    condition     = output.dlq_url != null
    error_message = "dlq_url must be non-null when create_dlq = true."
  }
}

# ── Test 2: Create a queue without a DLQ ─────────────────────────────────────
# SKIP_IN_CI
run "create_queue_without_dlq" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name       = "tftest-sqs-no-dlq"
    create_dlq = false
    environment = "test"
  }

  assert {
    condition     = length(output.queue_url) > 0
    error_message = "queue_url must be non-empty."
  }

  assert {
    condition     = can(regex("sqs", output.queue_url))
    error_message = "queue_url must contain 'sqs'."
  }

  assert {
    condition     = output.dlq_url == null
    error_message = "dlq_url must be null when create_dlq = false."
  }
}

# ── Test 3: Create a queue with custom retention and delay ───────────────────
# SKIP_IN_CI
run "create_queue_custom_settings" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                      = "tftest-sqs-custom"
    message_retention_seconds = 86400
    delay_seconds             = 10
    receive_wait_time_seconds = 20
    create_dlq                = false
    environment               = "test"
  }

  assert {
    condition     = can(regex("sqs", output.queue_url))
    error_message = "queue_url must contain 'sqs'."
  }

  assert {
    condition     = var.message_retention_seconds == 86400
    error_message = "message_retention_seconds must be 86400."
  }
}
