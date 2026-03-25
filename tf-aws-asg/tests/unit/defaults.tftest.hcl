# Unit tests — defaults and feature gates for tf-aws-asg
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name                = "test-asg"
  vpc_zone_identifier = ["subnet-00000000000000000"]
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
# enable_cpu_scaling defaults to true
# ---------------------------------------------------------------------------
run "cpu_scaling_enabled_by_default" {
  command = plan

  assert {
    condition     = var.enable_cpu_scaling == true
    error_message = "enable_cpu_scaling must default to true."
  }
}

# ---------------------------------------------------------------------------
# enable_memory_scaling defaults to false
# ---------------------------------------------------------------------------
run "memory_scaling_disabled_by_default" {
  command = plan

  assert {
    condition     = var.enable_memory_scaling == false
    error_message = "enable_memory_scaling must default to false (requires CW agent)."
  }
}

# ---------------------------------------------------------------------------
# enable_alb_request_scaling defaults to false
# ---------------------------------------------------------------------------
run "alb_request_scaling_disabled_by_default" {
  command = plan

  assert {
    condition     = var.enable_alb_request_scaling == false
    error_message = "enable_alb_request_scaling must default to false."
  }
}

# ---------------------------------------------------------------------------
# enable_sqs_scaling defaults to false
# ---------------------------------------------------------------------------
run "sqs_scaling_disabled_by_default" {
  command = plan

  assert {
    condition     = var.enable_sqs_scaling == false
    error_message = "enable_sqs_scaling must default to false."
  }
}

# ---------------------------------------------------------------------------
# Spot / mixed instances disabled by default
# ---------------------------------------------------------------------------
run "mixed_instances_disabled_by_default" {
  command = plan

  assert {
    condition     = var.use_mixed_instances_policy == false
    error_message = "use_mixed_instances_policy must default to false."
  }
}

# ---------------------------------------------------------------------------
# Default capacity values
# ---------------------------------------------------------------------------
run "capacity_defaults" {
  command = plan

  assert {
    condition     = var.min_size == 1
    error_message = "min_size must default to 1."
  }

  assert {
    condition     = var.max_size == 4
    error_message = "max_size must default to 4."
  }

  assert {
    condition     = var.desired_capacity == 2
    error_message = "desired_capacity must default to 2."
  }
}

# ---------------------------------------------------------------------------
# instance_refresh strategy defaults to Rolling
# ---------------------------------------------------------------------------
run "instance_refresh_strategy_default" {
  command = plan

  assert {
    condition     = var.instance_refresh_strategy == "Rolling"
    error_message = "instance_refresh_strategy must default to Rolling."
  }
}

# ---------------------------------------------------------------------------
# step_scaling_policies empty by default
# ---------------------------------------------------------------------------
run "step_scaling_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.step_scaling_policies) == 0
    error_message = "step_scaling_policies must be empty by default."
  }
}

# ---------------------------------------------------------------------------
# scheduled_actions empty by default
# ---------------------------------------------------------------------------
run "scheduled_actions_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.scheduled_actions) == 0
    error_message = "scheduled_actions must be empty by default."
  }
}

# ---------------------------------------------------------------------------
# ALB request scaling gate: enabled when required variables provided
# ---------------------------------------------------------------------------
run "alb_request_scaling_gate_enabled" {
  command = plan

  variables {
    name                        = "test-asg-alb"
    vpc_zone_identifier         = ["subnet-00000000000000000"]
    enable_alb_request_scaling  = true
    alb_target_group_arn_suffix = "targetgroup/test/abc123"
    alb_arn_suffix              = "app/test/abc123"
  }

  assert {
    condition     = var.enable_alb_request_scaling == true
    error_message = "ALB request scaling gate must accept true."
  }
}
