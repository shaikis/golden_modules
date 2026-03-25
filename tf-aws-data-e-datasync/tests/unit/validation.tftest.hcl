# Unit test: verify variable validation rules for DataSync.
# command = plan — no AWS resources are created.

# ── Test 1: Alarm period and evaluation period accept valid values ─────────────
run "valid_alarm_config" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    alarm_evaluation_periods = 3
    alarm_period_seconds     = 60
  }

  assert {
    condition     = var.alarm_evaluation_periods == 3
    error_message = "alarm_evaluation_periods must accept 3."
  }

  assert {
    condition     = var.alarm_period_seconds == 60
    error_message = "alarm_period_seconds must accept 60."
  }
}

# ── Test 2: s3_locations map with valid fields is accepted ────────────────────
run "s3_locations_map_structure" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_s3_locations = true
    s3_locations = {
      source = {
        s3_bucket_arn    = "arn:aws:s3:::my-source-bucket"
        subdirectory     = "/data"
        s3_storage_class = "STANDARD"
      }
    }
  }

  assert {
    condition     = length(var.s3_locations) == 1
    error_message = "s3_locations must accept a single entry."
  }
}

# ── Test 3: s3_bucket_arns_for_role defaults to empty list ───────────────────
run "s3_bucket_arns_defaults_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.s3_bucket_arns_for_role) == 0
    error_message = "s3_bucket_arns_for_role must default to empty list."
  }
}

# ── Test 4: Tasks require source and destination keys ─────────────────────────
run "tasks_require_location_keys" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    tasks = {
      move_data = {
        source_location_key      = "source"
        destination_location_key = "destination"
      }
    }
  }

  assert {
    condition     = length(var.tasks) == 1
    error_message = "Task with source and destination keys must be accepted."
  }
}

# ── Test 5: Alarm SNS topic defaults to null ──────────────────────────────────
run "alarm_sns_topic_defaults_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "alarm_sns_topic_arn must default to null."
  }
}
