# Unit tests — tf-aws-rds variable validation
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Valid engine values are accepted
# ---------------------------------------------------------------------------
run "valid_engine_postgres" {
  command = plan

  variables {
    name                 = "test-rds-pg"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "postgres"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "postgres"
    error_message = "Engine postgres should be accepted."
  }
}

run "valid_engine_mysql" {
  command = plan

  variables {
    name                 = "test-rds-mysql"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "mysql"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "mysql"
    error_message = "Engine mysql should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Valid storage types
# ---------------------------------------------------------------------------
run "valid_storage_type_gp3" {
  command = plan

  variables {
    name                 = "test-rds-gp3"
    db_subnet_group_name = "existing-subnet-group"
    storage_type         = "gp3"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.storage_type == "gp3"
    error_message = "Storage type gp3 should be accepted."
  }
}

run "valid_storage_type_io1" {
  command = plan

  variables {
    name                 = "test-rds-io1"
    db_subnet_group_name = "existing-subnet-group"
    storage_type         = "io1"
    iops                 = 3000
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.storage_type == "io1"
    error_message = "Storage type io1 should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Monitoring interval valid values
# ---------------------------------------------------------------------------
run "valid_monitoring_interval_zero" {
  command = plan

  variables {
    name                 = "test-rds-mon0"
    db_subnet_group_name = "existing-subnet-group"
    monitoring_interval  = 0
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.monitoring_interval == 0
    error_message = "Monitoring interval 0 (disabled) should be accepted."
  }
}

run "valid_monitoring_interval_60" {
  command = plan

  variables {
    name                 = "test-rds-mon60"
    db_subnet_group_name = "existing-subnet-group"
    monitoring_interval  = 60
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.monitoring_interval == 60
    error_message = "Monitoring interval 60 should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Performance insights retention period
# ---------------------------------------------------------------------------
run "valid_perf_insights_retention" {
  command = plan

  variables {
    name                                  = "test-rds-pi"
    db_subnet_group_name                  = "existing-subnet-group"
    performance_insights_enabled          = true
    performance_insights_retention_period = 7
    skip_final_snapshot                   = true
    deletion_protection                   = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.performance_insights_retention_period == 7
    error_message = "Performance Insights retention of 7 days should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: allocated_storage default value is within valid range
# ---------------------------------------------------------------------------
run "valid_allocated_storage_default" {
  command = plan

  variables {
    name                 = "test-rds-storage"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.allocated_storage >= 20
    error_message = "Default allocated_storage should be at least 20 GiB."
  }
}
