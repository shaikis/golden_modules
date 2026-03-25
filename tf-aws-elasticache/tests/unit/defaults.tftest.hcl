# Unit tests — tf-aws-elasticache defaults and BYO patterns
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Minimal Redis cluster creation with defaults
# ---------------------------------------------------------------------------
run "defaults_redis_plan_succeeds" {
  command = plan

  variables {
    name = "test-redis"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "redis"
    error_message = "Default engine should be redis."
  }

  assert {
    condition     = var.engine_version == "7.0"
    error_message = "Default engine version should be 7.0."
  }

  assert {
    condition     = var.node_type == "cache.t3.micro"
    error_message = "Default node_type should be cache.t3.micro."
  }

  assert {
    condition     = var.at_rest_encryption_enabled == true
    error_message = "At-rest encryption should be enabled by default."
  }

  assert {
    condition     = var.transit_encryption_enabled == true
    error_message = "Transit encryption should be enabled by default."
  }

  assert {
    condition     = var.automatic_failover_enabled == true
    error_message = "Automatic failover should be enabled by default."
  }

  assert {
    condition     = var.multi_az_enabled == true
    error_message = "Multi-AZ should be enabled by default."
  }

  assert {
    condition     = var.num_cache_clusters == 2
    error_message = "Default num_cache_clusters should be 2."
  }

  assert {
    condition     = var.snapshot_retention_limit == 7
    error_message = "Default snapshot retention should be 7 days."
  }
}

# ---------------------------------------------------------------------------
# Test: Memcached engine selection
# ---------------------------------------------------------------------------
run "memcached_engine" {
  command = plan

  variables {
    name            = "test-memcached"
    engine          = "memcached"
    num_cache_nodes = 2
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "memcached"
    error_message = "Engine should be memcached."
  }

  assert {
    condition     = var.num_cache_nodes == 2
    error_message = "num_cache_nodes should be 2 for memcached."
  }
}

# ---------------------------------------------------------------------------
# Test: BYO KMS key
# ---------------------------------------------------------------------------
run "byo_kms_key" {
  command = plan

  variables {
    name       = "test-redis-kms"
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
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
# Test: BYO subnet group
# ---------------------------------------------------------------------------
run "byo_subnet_group" {
  command = plan

  variables {
    name              = "test-redis-subnet"
    subnet_group_name = "existing-cache-subnet-group"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.subnet_group_name == "existing-cache-subnet-group"
    error_message = "BYO subnet group name should be passed through."
  }
}

# ---------------------------------------------------------------------------
# Test: Custom parameter group disabled by default
# ---------------------------------------------------------------------------
run "parameter_group_disabled_by_default" {
  command = plan

  variables {
    name = "test-redis-pg"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_parameter_group == false
    error_message = "create_parameter_group should be false by default."
  }
}

# ---------------------------------------------------------------------------
# Test: Custom parameter group enabled
# ---------------------------------------------------------------------------
run "parameter_group_enabled" {
  command = plan

  variables {
    name                  = "test-redis-cpg"
    create_parameter_group = true
    parameter_group_family = "redis7"
    parameters = [
      {
        name  = "maxmemory-policy"
        value = "allkeys-lru"
      }
    ]
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_parameter_group == true
    error_message = "create_parameter_group should be true when enabled."
  }
}

# ---------------------------------------------------------------------------
# Test: Single shard (num_node_groups = 1) is the default
# ---------------------------------------------------------------------------
run "single_shard_default" {
  command = plan

  variables {
    name = "test-redis-shard"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.num_node_groups == 1
    error_message = "Default num_node_groups should be 1 (single shard)."
  }

  assert {
    condition     = var.replicas_per_node_group == 1
    error_message = "Default replicas_per_node_group should be 1."
  }
}
