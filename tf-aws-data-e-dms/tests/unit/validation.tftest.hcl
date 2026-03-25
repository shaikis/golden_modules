# Unit test: variable validation rules for tf-aws-data-e-dms
# command = plan  →  free, no AWS resources are created

# ── Alarm threshold defaults ───────────────────────────────────────────────────

run "alarm_thresholds_have_sensible_defaults" {
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
    condition     = var.alarm_cdc_latency_source_threshold == 60
    error_message = "alarm_cdc_latency_source_threshold must default to 60 seconds"
  }

  assert {
    condition     = var.alarm_cdc_latency_target_threshold == 60
    error_message = "alarm_cdc_latency_target_threshold must default to 60 seconds"
  }

  assert {
    condition     = var.alarm_evaluation_periods == 3
    error_message = "alarm_evaluation_periods must default to 3"
  }

  assert {
    condition     = var.alarm_period_seconds == 300
    error_message = "alarm_period_seconds must default to 300"
  }
}

# ── Replication instance field defaults ───────────────────────────────────────

run "replication_instance_object_defaults" {
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
  }

  assert {
    condition     = var.replication_instances["main"].multi_az == false
    error_message = "multi_az must default to false"
  }

  assert {
    condition     = var.replication_instances["main"].publicly_accessible == false
    error_message = "publicly_accessible must default to false"
  }

  assert {
    condition     = var.replication_instances["main"].auto_minor_version_upgrade == true
    error_message = "auto_minor_version_upgrade must default to true"
  }

  assert {
    condition     = var.replication_instances["main"].apply_immediately == false
    error_message = "apply_immediately must default to false"
  }

  assert {
    condition     = var.replication_instances["main"].allow_major_version_upgrade == false
    error_message = "allow_major_version_upgrade must default to false"
  }
}

# ── Endpoint field defaults ────────────────────────────────────────────────────

run "endpoint_object_ssl_mode_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    replication_instances = {
      main = {}
    }

    endpoints = {
      source = {
        endpoint_type = "SOURCE"
        engine_name   = "mysql"
      }
    }
  }

  assert {
    condition     = var.endpoints["source"].ssl_mode == "none"
    error_message = "ssl_mode must default to 'none'"
  }
}

# ── Tags are a simple map ──────────────────────────────────────────────────────

run "tags_accepts_map" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    replication_instances = { main = {} }
    tags = {
      project     = "data-platform"
      cost_center = "engineering"
    }
  }

  assert {
    condition     = var.tags["project"] == "data-platform"
    error_message = "tags map was not accepted correctly"
  }
}
