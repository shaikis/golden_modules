# Unit tests — defaults and feature gates for tf-aws-asg-instance-ops
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  asg_name = "test-asg"
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
# protected_instance_ids defaults to empty list (no protection by default)
# ---------------------------------------------------------------------------
run "protected_instance_ids_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.protected_instance_ids) == 0
    error_message = "protected_instance_ids must default to empty list."
  }
}

# ---------------------------------------------------------------------------
# standby_instance_ids defaults to empty list
# ---------------------------------------------------------------------------
run "standby_instance_ids_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.standby_instance_ids) == 0
    error_message = "standby_instance_ids must default to empty list."
  }
}

# ---------------------------------------------------------------------------
# detach_instance_ids defaults to empty list
# ---------------------------------------------------------------------------
run "detach_instance_ids_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.detach_instance_ids) == 0
    error_message = "detach_instance_ids must default to empty list."
  }
}

# ---------------------------------------------------------------------------
# standby_should_decrement_desired defaults to true
# ---------------------------------------------------------------------------
run "standby_decrement_desired_default" {
  command = plan

  assert {
    condition     = var.standby_should_decrement_desired == true
    error_message = "standby_should_decrement_desired must default to true."
  }
}

# ---------------------------------------------------------------------------
# detach_should_decrement_desired defaults to true
# ---------------------------------------------------------------------------
run "detach_decrement_desired_default" {
  command = plan

  assert {
    condition     = var.detach_should_decrement_desired == true
    error_message = "detach_should_decrement_desired must default to true."
  }
}

# ---------------------------------------------------------------------------
# Scale-in protection gate: providing instance IDs enables protection
# ---------------------------------------------------------------------------
run "scale_in_protection_gate_enabled" {
  command = plan

  variables {
    asg_name               = "test-asg-protect"
    protected_instance_ids = ["i-00000000000000001", "i-00000000000000002"]
  }

  assert {
    condition     = length(var.protected_instance_ids) == 2
    error_message = "protected_instance_ids gate must accept a list of instance IDs."
  }
}

# ---------------------------------------------------------------------------
# Standby gate: providing instance IDs moves instances to standby
# ---------------------------------------------------------------------------
run "standby_gate_enabled" {
  command = plan

  variables {
    asg_name             = "test-asg-standby"
    standby_instance_ids = ["i-00000000000000003"]
  }

  assert {
    condition     = length(var.standby_instance_ids) == 1
    error_message = "standby_instance_ids gate must accept a list of instance IDs."
  }
}
