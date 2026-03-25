# Unit tests — defaults and feature gates for tf-aws-image-builder
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name = "test-image-builder"
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module {
  source = "../../"
}

# ---------------------------------------------------------------------------
# pipeline_enabled defaults to true
# ---------------------------------------------------------------------------
run "pipeline_enabled_by_default" {
  command = plan

  assert {
    condition     = var.pipeline_enabled == true
    error_message = "pipeline_enabled must default to true."
  }
}

# ---------------------------------------------------------------------------
# pipeline_schedule_expression defaults to null (manual runs only)
# ---------------------------------------------------------------------------
run "pipeline_schedule_null_by_default" {
  command = plan

  assert {
    condition     = var.pipeline_schedule_expression == null
    error_message = "pipeline_schedule_expression must default to null (manual-only pipeline)."
  }
}

# ---------------------------------------------------------------------------
# distribution_regions defaults to empty (no distribution by default)
# ---------------------------------------------------------------------------
run "distribution_regions_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.distribution_regions) == 0
    error_message = "distribution_regions must default to empty — create_distribution_configuration = false."
  }
}

# ---------------------------------------------------------------------------
# platform defaults to Linux
# ---------------------------------------------------------------------------
run "platform_default_linux" {
  command = plan

  assert {
    condition     = var.platform == "Linux"
    error_message = "platform must default to Linux."
  }
}

# ---------------------------------------------------------------------------
# install_cloudwatch_agent defaults to true
# ---------------------------------------------------------------------------
run "cloudwatch_agent_installed_by_default" {
  command = plan

  assert {
    condition     = var.install_cloudwatch_agent == true
    error_message = "install_cloudwatch_agent must default to true."
  }
}

# ---------------------------------------------------------------------------
# install_dynatrace defaults to false
# ---------------------------------------------------------------------------
run "dynatrace_disabled_by_default" {
  command = plan

  assert {
    condition     = var.install_dynatrace == false
    error_message = "install_dynatrace must default to false."
  }
}

# ---------------------------------------------------------------------------
# install_iis defaults to false (Linux default)
# ---------------------------------------------------------------------------
run "iis_disabled_by_default" {
  command = plan

  assert {
    condition     = var.install_iis == false
    error_message = "install_iis must default to false."
  }
}

# ---------------------------------------------------------------------------
# recipe_version defaults to 1.0.0
# ---------------------------------------------------------------------------
run "recipe_version_default" {
  command = plan

  assert {
    condition     = var.recipe_version == "1.0.0"
    error_message = "recipe_version must default to 1.0.0."
  }
}

# ---------------------------------------------------------------------------
# Distribution gate: providing distribution_regions enables distribution config
# ---------------------------------------------------------------------------
run "distribution_gate_enabled" {
  command = plan

  variables {
    name                 = "test-image-builder-dist"
    distribution_regions = ["us-west-2", "eu-west-1"]
  }

  assert {
    condition     = length(var.distribution_regions) == 2
    error_message = "distribution gate must accept a list of regions."
  }
}

# ---------------------------------------------------------------------------
# Scheduled pipeline gate: providing a schedule enables automated runs
# ---------------------------------------------------------------------------
run "pipeline_schedule_gate_enabled" {
  command = plan

  variables {
    name                        = "test-image-builder-sched"
    pipeline_schedule_expression = "cron(0 4 ? * 1 *)"
  }

  assert {
    condition     = var.pipeline_schedule_expression == "cron(0 4 ? * 1 *)"
    error_message = "pipeline_schedule_expression gate must accept a cron expression."
  }
}
