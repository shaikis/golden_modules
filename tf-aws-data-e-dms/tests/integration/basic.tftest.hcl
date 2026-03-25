# Integration test: creates a minimal DMS replication instance and verifies outputs
# command = apply  →  real AWS resources are created then destroyed
# SKIP_IN_CI

variables {
  replication_instances = {
    main = {
      replication_instance_class = "dms.t3.medium"
      allocated_storage          = 50
      multi_az                   = false
      engine_version             = "3.5.2"
      publicly_accessible        = false
    }
  }

  # Feature gates: keep all optional gates off for a minimal footprint
  create_alarms             = false
  create_event_subscriptions = false
  create_certificates       = false

  # Auto-create DMS IAM roles (dms-vpc-role, dms-cloudwatch-logs-role)
  create_iam_roles = true

  tags = {
    env     = "integration-test"
    managed = "terraform-test"
  }
}

# ── Apply: create resources ───────────────────────────────────────────────────

run "creates_replication_instance" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  # Replication instance was created and ARN is populated
  assert {
    condition     = length(output.replication_instance_arns) == 1
    error_message = "Expected exactly one replication instance ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:dms:", values(output.replication_instance_arns)[0]))
    error_message = "Replication instance ARN does not have expected DMS prefix"
  }

  # No endpoints created (gate was off)
  assert {
    condition     = length(output.endpoint_arns) == 0
    error_message = "Expected no endpoint ARNs when endpoints map is empty"
  }

  # No tasks created (gate was off)
  assert {
    condition     = length(output.task_arns) == 0
    error_message = "Expected no task ARNs when replication_tasks map is empty"
  }

  # IAM roles were created
  assert {
    condition     = can(regex("^arn:aws:iam::", output.dms_vpc_role_arn))
    error_message = "Expected dms_vpc_role_arn to be a valid IAM ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::", output.dms_logs_role_arn))
    error_message = "Expected dms_logs_role_arn to be a valid IAM ARN"
  }

  # Alarm map is empty because create_alarms = false
  assert {
    condition     = length(output.alarm_arns) == 0
    error_message = "Expected no alarm ARNs when create_alarms = false"
  }
}
