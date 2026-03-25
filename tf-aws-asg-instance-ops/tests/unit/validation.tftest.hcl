# Unit tests — variable validation rules for tf-aws-asg-instance-ops
# command = plan  →  no AWS resources are created; free to run on every PR.

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
# asg_name: required string is accepted
# ---------------------------------------------------------------------------
run "asg_name_accepted" {
  command = plan

  variables {
    asg_name = "my-production-asg"
  }

  assert {
    condition     = var.asg_name == "my-production-asg"
    error_message = "asg_name must be accepted as-is."
  }
}

# ---------------------------------------------------------------------------
# Multiple instance IDs in protected_instance_ids accepted
# ---------------------------------------------------------------------------
run "multiple_protected_instance_ids_accepted" {
  command = plan

  variables {
    asg_name               = "test-asg"
    protected_instance_ids = ["i-aaaaaaaaaaaaaaaaa", "i-bbbbbbbbbbbbbbbbb", "i-ccccccccccccccccc"]
  }

  assert {
    condition     = length(var.protected_instance_ids) == 3
    error_message = "protected_instance_ids must accept a list of 3 instance IDs."
  }
}

# ---------------------------------------------------------------------------
# standby_should_decrement_desired = false accepted
# ---------------------------------------------------------------------------
run "standby_no_decrement_accepted" {
  command = plan

  variables {
    asg_name                        = "test-asg"
    standby_instance_ids            = ["i-aaaaaaaaaaaaaaaaa"]
    standby_should_decrement_desired = false
  }

  assert {
    condition     = var.standby_should_decrement_desired == false
    error_message = "standby_should_decrement_desired = false must be accepted."
  }
}

# ---------------------------------------------------------------------------
# detach_should_decrement_desired = false accepted
# ---------------------------------------------------------------------------
run "detach_no_decrement_accepted" {
  command = plan

  variables {
    asg_name                        = "test-asg"
    detach_instance_ids             = ["i-aaaaaaaaaaaaaaaaa"]
    detach_should_decrement_desired  = false
  }

  assert {
    condition     = var.detach_should_decrement_desired == false
    error_message = "detach_should_decrement_desired = false must be accepted."
  }
}

# ---------------------------------------------------------------------------
# All three operations can be specified simultaneously
# ---------------------------------------------------------------------------
run "all_operations_simultaneously_accepted" {
  command = plan

  variables {
    asg_name               = "test-asg-all"
    protected_instance_ids = ["i-aaaaaaaaaaaaaaaaa"]
    standby_instance_ids   = ["i-bbbbbbbbbbbbbbbbb"]
    detach_instance_ids    = ["i-ccccccccccccccccc"]
  }

  assert {
    condition     = length(var.protected_instance_ids) == 1 && length(var.standby_instance_ids) == 1 && length(var.detach_instance_ids) == 1
    error_message = "All three instance operation lists must be accepted simultaneously."
  }
}

# ---------------------------------------------------------------------------
# environment tag accepted
# ---------------------------------------------------------------------------
run "environment_tag_accepted" {
  command = plan

  variables {
    asg_name    = "test-asg"
    environment = "production"
  }

  assert {
    condition     = var.environment == "production"
    error_message = "environment variable must accept 'production'."
  }
}
