# Unit tests — tf-aws-rds-aurora defaults and BYO patterns
# command = plan (no AWS resources created)

variables {
  name                 = "test-aurora"
  db_subnet_group_name = "existing-subnet-group"
}

# ---------------------------------------------------------------------------
# Test: Minimal cluster creation with defaults
# ---------------------------------------------------------------------------
run "defaults_plan_succeeds" {
  command = plan

  variables {
    name                 = "test-aurora"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "aurora-postgresql"
    error_message = "Default engine should be aurora-postgresql."
  }

  assert {
    condition     = var.engine_mode == "provisioned"
    error_message = "Default engine_mode should be provisioned."
  }

  assert {
    condition     = var.storage_encrypted == true
    error_message = "Storage should be encrypted by default."
  }

  assert {
    condition     = var.backup_retention_period == 14
    error_message = "Default backup retention should be 14 days."
  }

  assert {
    condition     = var.manage_master_user_password == true
    error_message = "Master user password should be managed by default."
  }

  assert {
    condition     = var.deletion_protection == false
    error_message = "deletion_protection should be false for test."
  }
}

# ---------------------------------------------------------------------------
# Test: Serverless v2 disabled by default (empty serverlessv2_scaling)
# ---------------------------------------------------------------------------
run "serverless_v2_disabled_by_default" {
  command = plan

  variables {
    name                 = "test-aurora-sv2"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.serverlessv2_scaling) == 0
    error_message = "Serverless v2 should be disabled by default (empty list)."
  }
}

# ---------------------------------------------------------------------------
# Test: Global cluster disabled by default
# ---------------------------------------------------------------------------
run "global_cluster_disabled_by_default" {
  command = plan

  variables {
    name                 = "test-aurora-global"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_global_cluster == false
    error_message = "create_global_cluster should be false by default."
  }

  assert {
    condition     = var.global_cluster_identifier == null
    error_message = "global_cluster_identifier should be null by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Autoscaling disabled by default
# ---------------------------------------------------------------------------
run "autoscaling_disabled_by_default" {
  command = plan

  variables {
    name                 = "test-aurora-as"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.autoscaling_enabled == false
    error_message = "Autoscaling should be disabled by default."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO KMS key
# ---------------------------------------------------------------------------
run "byo_kms_key" {
  command = plan

  variables {
    name                 = "test-aurora-kms"
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
# Test: BYO monitoring role
# ---------------------------------------------------------------------------
run "byo_monitoring_role" {
  command = plan

  variables {
    name                   = "test-aurora-mon"
    db_subnet_group_name   = "existing-subnet-group"
    skip_final_snapshot    = true
    deletion_protection    = false
    create_monitoring_role = false
    monitoring_role_arn    = "arn:aws:iam::123456789012:role/test-aurora-monitoring-role"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_monitoring_role == false
    error_message = "create_monitoring_role should be false when BYO role is provided."
  }

  assert {
    condition     = var.monitoring_role_arn == "arn:aws:iam::123456789012:role/test-aurora-monitoring-role"
    error_message = "BYO monitoring role ARN should be passed through."
  }
}

# ---------------------------------------------------------------------------
# Test: Custom cluster parameter group
# ---------------------------------------------------------------------------
run "create_cluster_parameter_group" {
  command = plan

  variables {
    name                          = "test-aurora-cpg"
    db_subnet_group_name          = "existing-subnet-group"
    skip_final_snapshot           = true
    deletion_protection           = false
    create_cluster_parameter_group = true
    cluster_parameter_group_family = "aurora-postgresql15"
    cluster_parameters = [
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
    condition     = var.create_cluster_parameter_group == true
    error_message = "create_cluster_parameter_group should be true."
  }
}
