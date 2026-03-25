# Unit test: variable validation rules for tf-aws-data-e-batch
# command = plan  →  free, no AWS resources are created

# ── Compute environment object field defaults ─────────────────────────────────

run "compute_environment_object_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    compute_environments = {
      main = {
        compute_type = "FARGATE_SPOT"
      }
    }
  }

  assert {
    condition     = var.compute_environments["main"].type == "MANAGED"
    error_message = "compute environment type must default to MANAGED"
  }

  assert {
    condition     = var.compute_environments["main"].max_vcpus == 256
    error_message = "max_vcpus must default to 256"
  }

  assert {
    condition     = var.compute_environments["main"].min_vcpus == 0
    error_message = "min_vcpus must default to 0"
  }

  assert {
    condition     = var.compute_environments["main"].state == "ENABLED"
    error_message = "state must default to ENABLED"
  }

  assert {
    condition     = var.compute_environments["main"].spot_bid_percentage == 60
    error_message = "spot_bid_percentage must default to 60"
  }

  assert {
    condition     = var.compute_environments["main"].terminate_on_update == false
    error_message = "terminate_on_update must default to false"
  }
}

# ── Job definition object field defaults ──────────────────────────────────────

run "job_definition_object_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    compute_environments = {
      main = { compute_type = "FARGATE_SPOT" }
    }
    job_definitions = {
      etl = {
        image = "public.ecr.aws/amazonlinux/amazonlinux:latest"
      }
    }
  }

  assert {
    condition     = var.job_definitions["etl"].type == "container"
    error_message = "job definition type must default to container"
  }

  assert {
    condition     = var.job_definitions["etl"].vcpus == 1
    error_message = "vcpus must default to 1"
  }

  assert {
    condition     = var.job_definitions["etl"].memory == 2048
    error_message = "memory must default to 2048"
  }

  assert {
    condition     = var.job_definitions["etl"].retry_attempts == 1
    error_message = "retry_attempts must default to 1"
  }

  assert {
    condition     = var.job_definitions["etl"].propagate_tags == true
    error_message = "propagate_tags must default to true"
  }
}

# ── Alarm threshold defaults ───────────────────────────────────────────────────

run "alarm_threshold_defaults" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    compute_environments = { main = {} }
    alarm_thresholds     = {}
  }

  assert {
    condition     = var.alarm_thresholds.pending_job_count_max == 100
    error_message = "pending_job_count_max must default to 100"
  }

  assert {
    condition     = var.alarm_thresholds.failed_job_count_max == 10
    error_message = "failed_job_count_max must default to 10"
  }
}

# ── Tags ──────────────────────────────────────────────────────────────────────

run "tags_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    compute_environments = { main = {} }
    tags                 = { env = "test", team = "data-platform" }
  }

  assert {
    condition     = var.tags["team"] == "data-platform"
    error_message = "tags map was not accepted correctly"
  }
}
