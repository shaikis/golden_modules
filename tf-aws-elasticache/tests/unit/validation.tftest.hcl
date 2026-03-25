# Unit tests — tf-aws-elasticache variable validation
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: Valid engine redis
# ---------------------------------------------------------------------------
run "valid_engine_redis" {
  command = plan

  variables {
    name   = "test-redis-val"
    engine = "redis"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "redis"
    error_message = "redis engine should be valid."
  }
}

# ---------------------------------------------------------------------------
# Test: Valid engine memcached
# ---------------------------------------------------------------------------
run "valid_engine_memcached" {
  command = plan

  variables {
    name   = "test-memcached-val"
    engine = "memcached"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.engine == "memcached"
    error_message = "memcached engine should be valid."
  }
}

# ---------------------------------------------------------------------------
# Test: Invalid engine is rejected
# ---------------------------------------------------------------------------
run "invalid_engine_rejected" {
  command = plan

  variables {
    name   = "test-invalid-engine"
    engine = "dragonfly"
  }

  module {
    source = "../../"
  }

  expect_failures = [var.engine]
}

# ---------------------------------------------------------------------------
# Test: Port default is 6379 for Redis
# ---------------------------------------------------------------------------
run "default_redis_port" {
  command = plan

  variables {
    name   = "test-redis-port"
    engine = "redis"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.port == 6379
    error_message = "Default Redis port should be 6379."
  }
}

# ---------------------------------------------------------------------------
# Test: Maintenance window format accepted
# ---------------------------------------------------------------------------
run "maintenance_window_valid" {
  command = plan

  variables {
    name               = "test-redis-mw"
    maintenance_window = "mon:05:00-mon:06:00"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.maintenance_window == "mon:05:00-mon:06:00"
    error_message = "Maintenance window should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Snapshot window format accepted
# ---------------------------------------------------------------------------
run "snapshot_window_valid" {
  command = plan

  variables {
    name            = "test-redis-sw"
    snapshot_window = "04:00-05:00"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.snapshot_window == "04:00-05:00"
    error_message = "Snapshot window should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: parameter_group_family default
# ---------------------------------------------------------------------------
run "parameter_group_family_default" {
  command = plan

  variables {
    name = "test-redis-pgf"
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.parameter_group_family == "redis7"
    error_message = "Default parameter_group_family should be redis7."
  }
}
