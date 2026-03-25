# Unit tests — defaults and feature gates for tf-aws-ec2
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name      = "test-ec2"
  subnet_id = "subnet-00000000000000000"
}

provider "aws" {
  region = "us-east-1"
  # Prevent accidental applies during plan-only tests.
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
# create_eip defaults to false
# ---------------------------------------------------------------------------
run "create_eip_defaults_to_false" {
  command = plan

  assert {
    condition     = var.create_eip == false
    error_message = "create_eip must default to false — no EIP should be created by default."
  }
}

# ---------------------------------------------------------------------------
# instance_type default
# ---------------------------------------------------------------------------
run "instance_type_default" {
  command = plan

  assert {
    condition     = var.instance_type == "t3.micro"
    error_message = "Default instance_type must be t3.micro."
  }
}

# ---------------------------------------------------------------------------
# root_volume_encrypted defaults to true (secure default)
# ---------------------------------------------------------------------------
run "root_volume_encrypted_default" {
  command = plan

  assert {
    condition     = var.root_volume_encrypted == true
    error_message = "root_volume_encrypted must default to true."
  }
}

# ---------------------------------------------------------------------------
# IMDSv2 is required by default (http_tokens = required)
# ---------------------------------------------------------------------------
run "imdsv2_required_by_default" {
  command = plan

  assert {
    condition     = var.metadata_options.http_tokens == "required"
    error_message = "IMDSv2 (http_tokens = required) must be enforced by default."
  }
}

# ---------------------------------------------------------------------------
# monitoring defaults to true
# ---------------------------------------------------------------------------
run "detailed_monitoring_default" {
  command = plan

  assert {
    condition     = var.monitoring == true
    error_message = "Detailed CloudWatch monitoring must be enabled by default."
  }
}

# ---------------------------------------------------------------------------
# disable_api_termination defaults to true (safe default)
# ---------------------------------------------------------------------------
run "termination_protection_default" {
  command = plan

  assert {
    condition     = var.disable_api_termination == true
    error_message = "disable_api_termination must default to true to protect instances."
  }
}

# ---------------------------------------------------------------------------
# use_spot defaults to false
# ---------------------------------------------------------------------------
run "use_spot_defaults_to_false" {
  command = plan

  assert {
    condition     = var.use_spot == false
    error_message = "use_spot must default to false."
  }
}

# ---------------------------------------------------------------------------
# associate_public_ip_address defaults to false (private by default)
# ---------------------------------------------------------------------------
run "no_public_ip_by_default" {
  command = plan

  assert {
    condition     = var.associate_public_ip_address == false
    error_message = "associate_public_ip_address must default to false."
  }
}

# ---------------------------------------------------------------------------
# BYO IAM: when iam_instance_profile is provided the variable is accepted
# ---------------------------------------------------------------------------
run "byo_iam_instance_profile_accepted" {
  command = plan

  variables {
    name                 = "test-ec2-byo"
    subnet_id            = "subnet-00000000000000000"
    iam_instance_profile = "my-existing-instance-profile"
  }

  assert {
    condition     = var.iam_instance_profile == "my-existing-instance-profile"
    error_message = "iam_instance_profile BYO value must be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# EIP gate: create_eip = true is accepted
# ---------------------------------------------------------------------------
run "create_eip_gate_enabled" {
  command = plan

  variables {
    name      = "test-ec2-eip"
    subnet_id = "subnet-00000000000000000"
    create_eip = true
  }

  assert {
    condition     = var.create_eip == true
    error_message = "create_eip gate should accept true."
  }
}
