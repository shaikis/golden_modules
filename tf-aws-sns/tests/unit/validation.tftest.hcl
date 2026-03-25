# tests/unit/validation.tftest.hcl — tf-aws-sns
# Confirms well-formed variable combinations plan without errors.

variables {
  name = "test-topic"
}

# ---------------------------------------------------------------------------
# Minimal valid config
# ---------------------------------------------------------------------------
run "minimal_valid_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
  }
}

# ---------------------------------------------------------------------------
# Topic with subscriptions map
# ---------------------------------------------------------------------------
run "topic_with_subscriptions" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-topic"
    subscriptions = {
      ops_email = {
        protocol = "email"
        endpoint = "ops@example.com"
      }
    }
  }

  assert {
    condition     = length(var.subscriptions) == 1
    error_message = "subscriptions map should contain exactly one entry"
  }
}

# ---------------------------------------------------------------------------
# Encryption with KMS key
# ---------------------------------------------------------------------------
run "topic_with_kms" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-topic"
    kms_master_key_id  = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }
}

# ---------------------------------------------------------------------------
# FIFO topic with multiple options
# ---------------------------------------------------------------------------
run "fifo_topic_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                        = "test-topic.fifo"
    fifo_topic                  = true
    content_based_deduplication = true
    display_name                = "Test FIFO Topic"
  }
}

# ---------------------------------------------------------------------------
# Tags and name_prefix accepted
# ---------------------------------------------------------------------------
run "tags_and_prefix" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "alerts"
    name_prefix = "prod"
    tags = {
      Team = "platform"
    }
  }

  assert {
    condition     = var.tags["Team"] == "platform"
    error_message = "Custom tags should be accepted"
  }
}
