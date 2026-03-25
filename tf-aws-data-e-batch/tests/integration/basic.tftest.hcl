# Integration test: creates a minimal Batch compute environment and verifies outputs
# command = apply  →  real AWS resources are created then destroyed
# SKIP_IN_CI

variables {
  compute_environments = {
    main = {
      type         = "MANAGED"
      compute_type = "FARGATE_SPOT"
      max_vcpus    = 16
      min_vcpus    = 0
      state        = "ENABLED"
    }
  }

  # No job queues or job definitions in the minimal smoke-test
  job_queues      = {}
  job_definitions = {}

  # Feature gates off for minimal footprint
  create_scheduling_policies = false
  create_alarms              = false

  # Auto-create IAM roles
  create_iam_role = true

  tags = {
    env     = "integration-test"
    managed = "terraform-test"
  }
}

# ── Apply: create resources ───────────────────────────────────────────────────

run "creates_compute_environment_only" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  # Compute environment ARN is populated
  assert {
    condition     = length(output.compute_environment_arns) == 1
    error_message = "Expected exactly one compute environment ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:batch:", values(output.compute_environment_arns)[0]))
    error_message = "Compute environment ARN does not have expected batch prefix"
  }

  # No job queues created (not in variables)
  assert {
    condition     = length(output.job_queue_arns) == 0
    error_message = "Expected no job queue ARNs when job_queues map is empty"
  }

  # No job definitions created
  assert {
    condition     = length(output.job_definition_arns) == 0
    error_message = "Expected no job definition ARNs when job_definitions map is empty"
  }

  # No scheduling policies created
  assert {
    condition     = length(output.scheduling_policy_arns) == 0
    error_message = "Expected no scheduling policy ARNs when create_scheduling_policies = false"
  }

  # IAM service role auto-created
  assert {
    condition     = can(regex("^arn:aws:iam::", output.batch_service_role_arn))
    error_message = "Expected batch_service_role_arn to be a valid IAM ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::", output.ecs_task_execution_role_arn))
    error_message = "Expected ecs_task_execution_role_arn to be a valid IAM ARN"
  }
}
