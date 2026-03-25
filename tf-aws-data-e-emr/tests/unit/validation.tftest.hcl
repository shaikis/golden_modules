# Unit test: variable validation rules for tf-aws-data-e-emr
# command = plan  →  free, no AWS resources are created

# ── Cluster object field defaults ─────────────────────────────────────────────

run "cluster_object_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    clusters = {
      spark = {
        release_label = "emr-7.0.0"
      }
    }
  }

  assert {
    condition     = var.clusters["spark"].release_label == "emr-7.0.0"
    error_message = "release_label was not accepted"
  }

  assert {
    condition     = var.clusters["spark"].master_instance_type == "m5.xlarge"
    error_message = "master_instance_type must default to m5.xlarge"
  }

  assert {
    condition     = var.clusters["spark"].core_instance_type == "m5.xlarge"
    error_message = "core_instance_type must default to m5.xlarge"
  }

  assert {
    condition     = var.clusters["spark"].core_instance_count == 2
    error_message = "core_instance_count must default to 2"
  }

  assert {
    condition     = var.clusters["spark"].termination_protection == false
    error_message = "termination_protection must default to false"
  }

  assert {
    condition     = var.clusters["spark"].keep_alive == true
    error_message = "keep_alive must default to true"
  }

  assert {
    condition     = var.clusters["spark"].use_spot_for_core == false
    error_message = "use_spot_for_core must default to false"
  }
}

# ── Serverless application object defaults ────────────────────────────────────

run "serverless_application_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_serverless_applications = true
    serverless_applications = {
      etl = {
        type          = "SPARK"
        release_label = "emr-7.0.0"
      }
    }
  }

  assert {
    condition     = var.serverless_applications["etl"].type == "SPARK"
    error_message = "type must be SPARK"
  }

  assert {
    condition     = var.serverless_applications["etl"].auto_start == true
    error_message = "auto_start must default to true"
  }

  assert {
    condition     = var.serverless_applications["etl"].auto_stop == true
    error_message = "auto_stop must default to true"
  }

  assert {
    condition     = var.serverless_applications["etl"].idle_timeout_minutes == 15
    error_message = "idle_timeout_minutes must default to 15"
  }
}

# ── Alarm threshold object defaults ───────────────────────────────────────────

run "alarm_threshold_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    alarm_thresholds = {}
  }

  assert {
    condition     = var.alarm_thresholds.hdfs_utilization_percent == 80
    error_message = "hdfs_utilization_percent must default to 80"
  }

  assert {
    condition     = var.alarm_thresholds.live_data_nodes_min == 1
    error_message = "live_data_nodes_min must default to 1"
  }
}

# ── Tags ──────────────────────────────────────────────────────────────────────

run "tags_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    tags = { env = "test", team = "data-platform" }
  }

  assert {
    condition     = var.tags["env"] == "test"
    error_message = "tags map was not accepted correctly"
  }
}
