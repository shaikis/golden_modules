# Unit tests — variable validation rules for tf-aws-ec2
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
# tenancy: valid value "default" accepted
# ---------------------------------------------------------------------------
run "tenancy_default_accepted" {
  command = plan

  variables {
    name      = "test-ec2-tenancy"
    subnet_id = "subnet-00000000000000000"
    tenancy   = "default"
  }

  assert {
    condition     = var.tenancy == "default"
    error_message = "tenancy value 'default' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# tenancy: valid value "dedicated" accepted
# ---------------------------------------------------------------------------
run "tenancy_dedicated_accepted" {
  command = plan

  variables {
    name      = "test-ec2-tenancy"
    subnet_id = "subnet-00000000000000000"
    tenancy   = "dedicated"
  }

  assert {
    condition     = var.tenancy == "dedicated"
    error_message = "tenancy value 'dedicated' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# instance_initiated_shutdown_behavior: "stop" accepted
# ---------------------------------------------------------------------------
run "shutdown_behavior_stop_accepted" {
  command = plan

  variables {
    name                               = "test-ec2-shutdown"
    subnet_id                          = "subnet-00000000000000000"
    instance_initiated_shutdown_behavior = "stop"
  }

  assert {
    condition     = var.instance_initiated_shutdown_behavior == "stop"
    error_message = "instance_initiated_shutdown_behavior 'stop' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# instance_initiated_shutdown_behavior: "terminate" accepted
# ---------------------------------------------------------------------------
run "shutdown_behavior_terminate_accepted" {
  command = plan

  variables {
    name                               = "test-ec2-shutdown"
    subnet_id                          = "subnet-00000000000000000"
    instance_initiated_shutdown_behavior = "terminate"
  }

  assert {
    condition     = var.instance_initiated_shutdown_behavior == "terminate"
    error_message = "instance_initiated_shutdown_behavior 'terminate' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# root_volume_type: "gp3" default is accepted
# ---------------------------------------------------------------------------
run "root_volume_type_gp3_accepted" {
  command = plan

  variables {
    name             = "test-ec2-vol"
    subnet_id        = "subnet-00000000000000000"
    root_volume_type = "gp3"
  }

  assert {
    condition     = var.root_volume_type == "gp3"
    error_message = "root_volume_type 'gp3' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# root_volume_size: positive number accepted
# ---------------------------------------------------------------------------
run "root_volume_size_positive_accepted" {
  command = plan

  variables {
    name             = "test-ec2-volsize"
    subnet_id        = "subnet-00000000000000000"
    root_volume_size = 50
  }

  assert {
    condition     = var.root_volume_size == 50
    error_message = "root_volume_size positive value must be accepted."
  }
}

# ---------------------------------------------------------------------------
# source_dest_check: false accepted (for NAT use-case)
# ---------------------------------------------------------------------------
run "source_dest_check_false_accepted" {
  command = plan

  variables {
    name             = "test-ec2-nat"
    subnet_id        = "subnet-00000000000000000"
    source_dest_check = false
  }

  assert {
    condition     = var.source_dest_check == false
    error_message = "source_dest_check = false must be accepted (NAT instance use-case)."
  }
}

# ---------------------------------------------------------------------------
# ebs_volumes: empty map accepted
# ---------------------------------------------------------------------------
run "ebs_volumes_empty_map_accepted" {
  command = plan

  variables {
    name        = "test-ec2-ebs"
    subnet_id   = "subnet-00000000000000000"
    ebs_volumes = {}
  }

  assert {
    condition     = length(var.ebs_volumes) == 0
    error_message = "ebs_volumes empty map must be accepted."
  }
}
