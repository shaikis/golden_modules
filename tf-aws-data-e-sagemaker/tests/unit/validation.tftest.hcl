# Unit test: verify variable validation rules.
# command = plan — no AWS resources are created.

# ── Test 1: Alarm thresholds accept valid numeric values ──────────────────────
run "valid_alarm_thresholds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    alarm_model_latency_p99_ms  = 1000
    alarm_error_rate_threshold  = 10
    alarm_cpu_threshold         = 90
    alarm_memory_threshold      = 85
    alarm_disk_threshold        = 75
    alarm_evaluation_periods    = 5
    alarm_period_seconds        = 60
  }

  assert {
    condition     = var.alarm_model_latency_p99_ms == 1000
    error_message = "alarm_model_latency_p99_ms should accept 1000."
  }

  assert {
    condition     = var.alarm_evaluation_periods == 5
    error_message = "alarm_evaluation_periods should accept 5."
  }
}

# ── Test 2: Empty domains map is valid ────────────────────────────────────────
run "empty_domains_map_is_valid" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    domains = {}
  }

  assert {
    condition     = length(var.domains) == 0
    error_message = "Empty domains map should be accepted."
  }
}

# ── Test 3: Empty pipelines map with gate false is valid ──────────────────────
run "empty_pipelines_gate_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_pipelines = false
    pipelines        = {}
  }

  assert {
    condition     = var.create_pipelines == false && length(var.pipelines) == 0
    error_message = "Empty pipelines with gate=false must be valid."
  }
}

# ── Test 4: data_bucket_arns defaults to empty list ───────────────────────────
run "data_bucket_arns_defaults_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.data_bucket_arns) == 0
    error_message = "data_bucket_arns must default to an empty list."
  }
}

# ── Test 5: additional_policy_arns defaults to empty list ────────────────────
run "additional_policy_arns_defaults_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.additional_policy_arns) == 0
    error_message = "additional_policy_arns must default to an empty list."
  }
}
