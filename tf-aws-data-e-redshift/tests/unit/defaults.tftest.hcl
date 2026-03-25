# unit/defaults.tftest.hcl — tf-aws-data-e-redshift
# plan-only: verifies feature-gate defaults and BYO IAM/KMS pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only provisioned cluster resources planned
# ---------------------------------------------------------------------------
run "minimal_provisioned_cluster_plan" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
  }

  # Cluster must be planned
  assert {
    condition     = length(aws_redshift_cluster.this) == 1
    error_message = "Expected exactly one Redshift cluster to be planned."
  }

  # Serverless gate defaults to false
  assert {
    condition     = length(aws_redshiftserverless_namespace.this) == 0
    error_message = "create_serverless defaults to false; no serverless namespaces should be planned."
  }

  assert {
    condition     = length(aws_redshiftserverless_workgroup.this) == 0
    error_message = "create_serverless defaults to false; no serverless workgroups should be planned."
  }

  # Parameter groups gate defaults to false
  assert {
    condition     = length(aws_redshift_parameter_group.this) == 0
    error_message = "create_parameter_groups defaults to false; no parameter groups should be planned."
  }

  # Snapshot schedules gate defaults to false
  assert {
    condition     = length(aws_redshift_snapshot_schedule.this) == 0
    error_message = "create_snapshot_schedules defaults to false; no snapshot schedules should be planned."
  }

  # Scheduled actions gate defaults to false
  assert {
    condition     = length(aws_redshift_scheduled_action.this) == 0
    error_message = "create_scheduled_actions defaults to false; no scheduled actions should be planned."
  }

  # Data shares gate defaults to false
  assert {
    condition     = length(aws_redshift_data_share_authorization.this) == 0
    error_message = "create_data_shares defaults to false; no data share authorizations should be planned."
  }

  # Alarms gate defaults to false
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "create_alarms defaults to false; no CloudWatch alarms should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — BYO IAM role suppresses auto-create
# ---------------------------------------------------------------------------
run "byo_iam_role_suppresses_creation" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
    create_iam_role      = false
    role_arn             = "arn:aws:iam::123456789012:role/test"
  }

  assert {
    condition     = length(aws_iam_role.redshift) == 0
    error_message = "create_iam_role = false should prevent auto-creation of the Redshift IAM role."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — BYO KMS key suppresses aws_kms_key creation
# ---------------------------------------------------------------------------
run "byo_kms_key_suppresses_key_creation" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
        kms_key_id          = "arn:aws:kms:us-east-1:123456789012:key/abc123"
      }
    }
    create_subnet_groups = false
    kms_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/abc123"
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "When kms_key_arn is provided, the module must not create a KMS key."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_cluster" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
    tags                 = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_redshift_cluster.this["warehouse"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the Redshift cluster."
  }
}
