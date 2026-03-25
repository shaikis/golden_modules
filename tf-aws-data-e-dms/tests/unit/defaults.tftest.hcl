# Unit test: verify feature-gate defaults and BYO IAM/KMS pattern for tf-aws-data-e-dms
# command = plan  →  free, no AWS resources are created

variables {
  # Minimal valid config: one replication instance with all optional fields at defaults
  replication_instances = {
    main = {
      replication_instance_class = "dms.t3.medium"
      allocated_storage          = 50
    }
  }

  tags = { env = "test" }
}

# ── Gate defaults ─────────────────────────────────────────────────────────────

run "feature_gates_default_to_false" {
  command = plan

  module {
    source = "../../"
  }

  # All opt-in gates must default to false
  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms must default to false"
  }

  assert {
    condition     = var.create_event_subscriptions == false
    error_message = "create_event_subscriptions must default to false"
  }

  assert {
    condition     = var.create_certificates == false
    error_message = "create_certificates must default to false"
  }
}

run "iam_roles_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  # DMS requires its own IAM roles; create_iam_roles defaults to true
  assert {
    condition     = var.create_iam_roles == true
    error_message = "create_iam_roles must default to true so DMS VPC/logs roles are available"
  }
}

# ── BYO KMS pattern ───────────────────────────────────────────────────────────

run "kms_key_arn_defaults_to_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.kms_key_arn == null
    error_message = "kms_key_arn must default to null (AWS-managed key)"
  }
}

run "byo_kms_key_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    replication_instances = {
      main = {
        replication_instance_class = "dms.t3.medium"
      }
    }
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = var.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abc"
    error_message = "BYO KMS key ARN was not accepted correctly"
  }
}

# ── Alarm gate stays disabled without SNS topic ───────────────────────────────

run "alarm_sns_topic_defaults_to_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "alarm_sns_topic_arn must default to null"
  }
}

# ── Empty collections default ─────────────────────────────────────────────────

run "optional_collections_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    replication_instances = {
      main = {}
    }
  }

  assert {
    condition     = length(var.endpoints) == 0
    error_message = "endpoints must default to empty map"
  }

  assert {
    condition     = length(var.replication_tasks) == 0
    error_message = "replication_tasks must default to empty map"
  }

  assert {
    condition     = length(var.event_subscriptions) == 0
    error_message = "event_subscriptions must default to empty map"
  }

  assert {
    condition     = length(var.certificates) == 0
    error_message = "certificates must default to empty map"
  }

  assert {
    condition     = length(var.subnet_groups) == 0
    error_message = "subnet_groups must default to empty map"
  }
}
