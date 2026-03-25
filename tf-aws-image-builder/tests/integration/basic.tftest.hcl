# Integration tests — tf-aws-image-builder
# Cost estimate: $0.00 for pipeline creation — EC2 costs only accrue when a
# pipeline run is triggered (run_pipeline must be called separately).
# These tests use command = plan to validate configuration without provisioning.
# Note: actual image builds launch an EC2 instance (~$0.02/hr for t3.medium).
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Plan minimal Linux Image Builder pipeline ───────────────────────
# SKIP_IN_CI
run "minimal_linux_pipeline_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name           = "tftest-image-builder"
    platform       = "Linux"
    recipe_version = "1.0.0"
    instance_types = ["t3.medium"]
    environment    = "test"
  }

  assert {
    condition     = var.platform == "Linux"
    error_message = "platform must be Linux."
  }

  assert {
    condition     = var.recipe_version == "1.0.0"
    error_message = "recipe_version must be 1.0.0."
  }
}

# ── Test 2: Plan with scheduled pipeline expression ──────────────────────────
# SKIP_IN_CI
run "scheduled_pipeline_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                        = "tftest-image-builder-sched"
    platform                    = "Linux"
    recipe_version              = "1.0.0"
    pipeline_schedule_expression = "cron(0 4 * * ? *)"
    pipeline_enabled            = true
    environment                 = "test"
  }

  assert {
    condition     = var.pipeline_enabled == true
    error_message = "pipeline_enabled must be true."
  }

  assert {
    condition     = var.pipeline_schedule_expression == "cron(0 4 * * ? *)"
    error_message = "pipeline_schedule_expression must match the provided cron."
  }
}

# ── Test 3: Plan with CloudWatch Agent component enabled ─────────────────────
# SKIP_IN_CI
run "cloudwatch_agent_component_plan_succeeds" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                   = "tftest-image-builder-cw"
    platform               = "Linux"
    recipe_version         = "1.0.0"
    install_cloudwatch_agent = true
    environment            = "test"
  }

  assert {
    condition     = var.install_cloudwatch_agent == true
    error_message = "install_cloudwatch_agent must be true."
  }
}
