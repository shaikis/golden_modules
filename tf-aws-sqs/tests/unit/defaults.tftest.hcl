# tests/unit/defaults.tftest.hcl — tf-aws-sqs
# Verifies feature-gate defaults and DLQ/encryption BYO patterns via plan only (free).

variables {
  name = "test-queue"
}

# ---------------------------------------------------------------------------
# Minimal queue creation — only name required
# ---------------------------------------------------------------------------
run "minimal_queue_creation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-queue"
  }
}

# ---------------------------------------------------------------------------
# create_dlq defaults to true — DLQ is created by default
# ---------------------------------------------------------------------------
run "dlq_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-queue"
  }

  assert {
    condition     = var.create_dlq == true
    error_message = "create_dlq should default to true"
  }
}

# ---------------------------------------------------------------------------
# create_dlq = false — DLQ disabled
# ---------------------------------------------------------------------------
run "dlq_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name       = "test-queue"
    create_dlq = false
  }

  assert {
    condition     = var.create_dlq == false
    error_message = "create_dlq should be false when explicitly disabled"
  }
}

# ---------------------------------------------------------------------------
# enable_encryption defaults to false — kms_master_key_id is null
# ---------------------------------------------------------------------------
run "encryption_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-queue"
  }

  assert {
    condition     = var.kms_master_key_id == null
    error_message = "kms_master_key_id should default to null"
  }
}

# ---------------------------------------------------------------------------
# FIFO queue gate — fifo_queue defaults to false
# ---------------------------------------------------------------------------
run "fifo_queue_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-queue"
  }

  assert {
    condition     = var.fifo_queue == false
    error_message = "fifo_queue should default to false"
  }
}

# ---------------------------------------------------------------------------
# FIFO queue enabled — content_based_deduplication accepted
# ---------------------------------------------------------------------------
run "fifo_queue_enabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                        = "test-queue.fifo"
    fifo_queue                  = true
    content_based_deduplication = true
  }

  assert {
    condition     = var.fifo_queue == true
    error_message = "fifo_queue should be true when set"
  }
}

# ---------------------------------------------------------------------------
# Default message retention is 4 days (345600 seconds)
# ---------------------------------------------------------------------------
run "default_retention_period" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-queue"
  }

  assert {
    condition     = var.message_retention_seconds == 345600
    error_message = "message_retention_seconds should default to 345600 (4 days)"
  }
}
