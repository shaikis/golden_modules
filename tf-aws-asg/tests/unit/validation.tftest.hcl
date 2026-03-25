# Unit tests — variable validation rules for tf-aws-asg
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
# os_type: "linux" accepted
# ---------------------------------------------------------------------------
run "os_type_linux_accepted" {
  command = plan

  variables {
    name                = "test-asg-linux"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    os_type             = "linux"
  }

  assert {
    condition     = var.os_type == "linux"
    error_message = "os_type 'linux' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# os_type: "windows" accepted
# ---------------------------------------------------------------------------
run "os_type_windows_accepted" {
  command = plan

  variables {
    name                = "test-asg-windows"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    os_type             = "windows"
  }

  assert {
    condition     = var.os_type == "windows"
    error_message = "os_type 'windows' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# health_check_type: "EC2" accepted
# ---------------------------------------------------------------------------
run "health_check_type_ec2_accepted" {
  command = plan

  variables {
    name                = "test-asg-hc"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    health_check_type   = "EC2"
  }

  assert {
    condition     = var.health_check_type == "EC2"
    error_message = "health_check_type 'EC2' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# health_check_type: "ELB" accepted
# ---------------------------------------------------------------------------
run "health_check_type_elb_accepted" {
  command = plan

  variables {
    name                = "test-asg-elb"
    vpc_zone_identifier = ["subnet-00000000000000000"]
    health_check_type   = "ELB"
  }

  assert {
    condition     = var.health_check_type == "ELB"
    error_message = "health_check_type 'ELB' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# spot_allocation_strategy: default "price-capacity-optimized" accepted
# ---------------------------------------------------------------------------
run "spot_allocation_strategy_default" {
  command = plan

  variables {
    name                = "test-asg-spot"
    vpc_zone_identifier = ["subnet-00000000000000000"]
  }

  assert {
    condition     = var.spot_allocation_strategy == "price-capacity-optimized"
    error_message = "spot_allocation_strategy must default to price-capacity-optimized."
  }
}

# ---------------------------------------------------------------------------
# cpu_target_value: default 70 accepted
# ---------------------------------------------------------------------------
run "cpu_target_value_default" {
  command = plan

  variables {
    name                = "test-asg-cpu"
    vpc_zone_identifier = ["subnet-00000000000000000"]
  }

  assert {
    condition     = var.cpu_target_value == 70
    error_message = "cpu_target_value must default to 70."
  }
}

# ---------------------------------------------------------------------------
# instance_refresh_min_healthy_percentage: default 90 accepted
# ---------------------------------------------------------------------------
run "instance_refresh_min_healthy_default" {
  command = plan

  variables {
    name                = "test-asg-refresh"
    vpc_zone_identifier = ["subnet-00000000000000000"]
  }

  assert {
    condition     = var.instance_refresh_min_healthy_percentage == 90
    error_message = "instance_refresh_min_healthy_percentage must default to 90."
  }
}

# ---------------------------------------------------------------------------
# Windows domain join: empty strings accepted as defaults
# ---------------------------------------------------------------------------
run "windows_domain_join_defaults_empty" {
  command = plan

  variables {
    name                = "test-asg-domain"
    vpc_zone_identifier = ["subnet-00000000000000000"]
  }

  assert {
    condition     = var.windows_domain_name == ""
    error_message = "windows_domain_name must default to empty string."
  }
}
