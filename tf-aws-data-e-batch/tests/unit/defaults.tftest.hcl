# Unit test: verify feature-gate defaults and BYO IAM pattern for tf-aws-data-e-batch
# command = plan  →  free, no AWS resources are created

variables {
  compute_environments = {
    main = {
      compute_type = "FARGATE_SPOT"
      max_vcpus    = 256
    }
  }

  tags = { env = "test" }
}

# ── Gate defaults ─────────────────────────────────────────────────────────────

run "feature_gates_default_to_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_scheduling_policies == false
    error_message = "create_scheduling_policies must default to false"
  }

  assert {
    condition     = var.create_alarms == false
    error_message = "create_alarms must default to false"
  }
}

run "iam_role_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_role == true
    error_message = "create_iam_role must default to true"
  }
}

# ── BYO pattern ───────────────────────────────────────────────────────────────

run "byo_fields_default_to_null" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.role_arn == null
    error_message = "role_arn must default to null"
  }

  assert {
    condition     = var.alarm_sns_topic_arn == null
    error_message = "alarm_sns_topic_arn must default to null"
  }
}

run "byo_role_arn_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/batch-service-role"
    compute_environments = {
      main = {
        compute_type = "FARGATE_SPOT"
      }
    }
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/batch-service-role"
    error_message = "BYO role ARN was not accepted correctly"
  }
}

# ── Job queues not created by default ─────────────────────────────────────────

run "job_queues_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.job_queues) == 0
    error_message = "job_queues must default to empty — no queue unless explicitly defined"
  }
}

run "job_definitions_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.job_definitions) == 0
    error_message = "job_definitions must default to empty"
  }
}

run "scheduling_policies_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.scheduling_policies) == 0
    error_message = "scheduling_policies must default to empty"
  }
}
