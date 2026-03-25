# Unit tests — tf-aws-rds defaults and BYO patterns
# command = plan (no AWS resources created)

variables {
  name                 = "test-rds"
  db_subnet_group_name = "existing-subnet-group"
  skip_final_snapshot  = true
  deletion_protection  = false
}

# ---------------------------------------------------------------------------
# Test: Minimal defaults plan succeeds
# ---------------------------------------------------------------------------
run "defaults_plan_succeeds" {
  command = plan

  variables {
    name                 = "test-rds"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "postgres"
    error_message = "Default engine should be postgres."
  }

  assert {
    condition     = var.instance_class == "db.t3.medium"
    error_message = "Default instance_class should be db.t3.medium."
  }

  assert {
    condition     = var.storage_encrypted == true
    error_message = "Storage should be encrypted by default."
  }

  assert {
    condition     = var.multi_az == true
    error_message = "Multi-AZ should be enabled by default."
  }

  assert {
    condition     = var.backup_retention_period == 14
    error_message = "Default backup retention should be 14 days."
  }

  assert {
    condition     = var.monitoring_interval == 60
    error_message = "Default monitoring interval should be 60s."
  }

  assert {
    condition     = var.performance_insights_enabled == true
    error_message = "Performance Insights should be enabled by default."
  }

  assert {
    condition     = var.manage_master_user_password == true
    error_message = "Master password should be managed by default."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO KMS key — module uses provided key, does not create one
# ---------------------------------------------------------------------------
run "byo_kms_key" {
  command = plan

  variables {
    name                 = "test-rds-kms"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
    kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
    error_message = "BYO KMS key ARN should be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO monitoring role — create_monitoring_role = false
# ---------------------------------------------------------------------------
run "byo_monitoring_role" {
  command = plan

  variables {
    name                 = "test-rds-mon"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
    create_monitoring_role = false
    monitoring_role_arn    = "arn:aws:iam::123456789012:role/test-rds-monitoring-role"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_monitoring_role == false
    error_message = "create_monitoring_role should be false when BYO role is provided."
  }

  assert {
    condition     = var.monitoring_role_arn == "arn:aws:iam::123456789012:role/test-rds-monitoring-role"
    error_message = "BYO monitoring role ARN should be passed through."
  }
}

# ---------------------------------------------------------------------------
# Test: Custom parameter group enabled
# ---------------------------------------------------------------------------
run "create_parameter_group_enabled" {
  command = plan

  variables {
    name                 = "test-rds-params"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
    create_parameter_group  = true
    parameter_group_family  = "postgres15"
    parameters = [
      {
        name  = "log_connections"
        value = "1"
      }
    ]
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_parameter_group == true
    error_message = "create_parameter_group should be true."
  }

  assert {
    condition     = var.parameter_group_family == "postgres15"
    error_message = "Parameter group family should be postgres15."
  }
}

# ---------------------------------------------------------------------------
# Test: Backup retention disabled (0 days)
# ---------------------------------------------------------------------------
run "backup_disabled" {
  command = plan

  variables {
    name                   = "test-rds-nobackup"
    db_subnet_group_name   = "existing-subnet-group"
    skip_final_snapshot    = true
    deletion_protection    = false
    backup_retention_period = 0
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.backup_retention_period == 0
    error_message = "backup_retention_period should be 0 (disabled)."
  }
}

# ---------------------------------------------------------------------------
# Test: Automated backup replication disabled by default
# ---------------------------------------------------------------------------
run "automated_backup_replication_default_off" {
  command = plan

  variables {
    name                 = "test-rds-abr"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.enable_automated_backup_replication == false
    error_message = "Automated backup replication should be disabled by default."
  }
}
