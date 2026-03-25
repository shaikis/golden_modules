# Unit tests — variable validation for tf-aws-restore
# command = plan; no real AWS resources are created.

run "valid_log_retention_days_90" {
  command = plan

  variables {
    name                  = "test-restore-valid"
    enable_cloudwatch_logs = true
    log_retention_days    = 90
  }

  assert {
    condition     = var.log_retention_days == 90
    error_message = "log_retention_days = 90 should be accepted."
  }
}

run "valid_log_retention_days_365" {
  command = plan

  variables {
    name                  = "test-restore-365"
    enable_cloudwatch_logs = true
    log_retention_days    = 365
  }

  assert {
    condition     = var.log_retention_days == 365
    error_message = "log_retention_days = 365 should be accepted."
  }
}

# Negative test: invalid log_retention_days must be rejected by the validation block.
run "invalid_log_retention_days_rejected" {
  command = plan

  variables {
    name                  = "test-restore-bad-retention"
    enable_cloudwatch_logs = true
    log_retention_days    = 99
  }

  expect_failures = [
    var.log_retention_days,
  ]
}

run "restore_testing_plan_with_valid_algorithm" {
  command = plan

  variables {
    name = "test-restore-plan"
    restore_testing_plans = {
      weekly = {
        algorithm            = "LATEST_WITHIN_WINDOW"
        recovery_point_types = ["SNAPSHOT"]
        schedule_expression  = "cron(0 6 ? * SUN *)"
        start_window_hours   = 2
      }
    }
  }

  assert {
    condition     = length(var.restore_testing_plans) == 1
    error_message = "Expected one restore_testing_plan to be configured."
  }
}
