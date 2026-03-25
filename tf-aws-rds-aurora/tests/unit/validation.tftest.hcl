# Unit tests — tf-aws-rds-aurora variable validation
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Valid engine — aurora-postgresql
# ---------------------------------------------------------------------------
run "valid_engine_aurora_postgresql" {
  command = plan

  variables {
    name                 = "test-aurora-pg"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "aurora-postgresql"
    engine_version       = "15.4"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "aurora-postgresql"
    error_message = "aurora-postgresql engine should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Valid engine — aurora-mysql
# ---------------------------------------------------------------------------
run "valid_engine_aurora_mysql" {
  command = plan

  variables {
    name                 = "test-aurora-mysql"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "aurora-mysql"
    engine_version       = "8.0.mysql_aurora.3.04.0"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "aurora-mysql"
    error_message = "aurora-mysql engine should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Invalid engine is rejected
# ---------------------------------------------------------------------------
run "invalid_engine_rejected" {
  command = plan

  variables {
    name                 = "test-aurora-bad"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "invalid-engine"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  expect_failures = [var.engine]
}

# ---------------------------------------------------------------------------
# Test: Cluster instances default has writer and reader
# ---------------------------------------------------------------------------
run "default_cluster_instances" {
  command = plan

  variables {
    name                 = "test-aurora-inst"
    db_subnet_group_name = "existing-subnet-group"
    skip_final_snapshot  = true
    deletion_protection  = false
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.cluster_instances) == 2
    error_message = "Default cluster_instances should have 2 entries (writer + reader)."
  }
}

# ---------------------------------------------------------------------------
# Test: Serverless v2 scaling configuration is valid
# ---------------------------------------------------------------------------
run "serverless_v2_scaling_valid" {
  command = plan

  variables {
    name                 = "test-aurora-sv2"
    db_subnet_group_name = "existing-subnet-group"
    engine               = "aurora-postgresql"
    engine_mode          = "provisioned"
    instance_class       = "db.serverless"
    skip_final_snapshot  = true
    deletion_protection  = false
    serverlessv2_scaling = [
      {
        min_capacity = 0.5
        max_capacity = 4.0
      }
    ]
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.serverlessv2_scaling) == 1
    error_message = "Serverless v2 scaling config should be accepted."
  }

  assert {
    condition     = var.serverlessv2_scaling[0].min_capacity == 0.5
    error_message = "min_capacity should be 0.5."
  }
}

# ---------------------------------------------------------------------------
# Test: Backup retention period within valid range
# ---------------------------------------------------------------------------
run "backup_retention_valid" {
  command = plan

  variables {
    name                    = "test-aurora-bk"
    db_subnet_group_name    = "existing-subnet-group"
    skip_final_snapshot     = true
    deletion_protection     = false
    backup_retention_period = 7
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.backup_retention_period == 7
    error_message = "Backup retention period of 7 days should be valid."
  }
}
