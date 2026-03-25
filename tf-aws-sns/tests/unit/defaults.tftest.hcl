# tests/unit/defaults.tftest.hcl — tf-aws-sns
# Verifies feature-gate defaults and subscription/encryption BYO patterns via plan only (free).

variables {
  name = "test-topic"
}

# ---------------------------------------------------------------------------
# Minimal topic creation — only name required
# ---------------------------------------------------------------------------
run "minimal_topic_creation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
  }
}

# ---------------------------------------------------------------------------
# create_subscriptions defaults to false — subscriptions map is empty
# ---------------------------------------------------------------------------
run "no_subscriptions_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
  }

  assert {
    condition     = length(var.subscriptions) == 0
    error_message = "subscriptions should default to an empty map"
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
    name = "test-topic"
  }

  assert {
    condition     = var.kms_master_key_id == null
    error_message = "kms_master_key_id should default to null (encryption disabled)"
  }
}

# ---------------------------------------------------------------------------
# FIFO topic gate — fifo_topic defaults to false
# ---------------------------------------------------------------------------
run "fifo_topic_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
  }

  assert {
    condition     = var.fifo_topic == false
    error_message = "fifo_topic should default to false"
  }
}

# ---------------------------------------------------------------------------
# FIFO topic enabled — content_based_deduplication accepted
# ---------------------------------------------------------------------------
run "fifo_topic_enabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                        = "test-topic.fifo"
    fifo_topic                  = true
    content_based_deduplication = true
  }

  assert {
    condition     = var.fifo_topic == true
    error_message = "fifo_topic should be true when set"
  }
}

# ---------------------------------------------------------------------------
# display_name defaults to null
# ---------------------------------------------------------------------------
run "display_name_null_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
  }

  assert {
    condition     = var.display_name == null
    error_message = "display_name should default to null"
  }
}
