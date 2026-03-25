# Unit tests — variable validation rules for tf-aws-eni
# Verifies structural correctness of ENI definitions including optional fields.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: EIP attachment config accepted per ENI
# ---------------------------------------------------------------------------
run "eip_attachment_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      public_eni = {
        subnet_id = "subnet-00000000000000000"
        eip = {
          domain = "vpc"
        }
      }
    }
  }

  assert {
    condition     = var.network_interfaces["public_eni"].eip != null
    error_message = "EIP config block should be accepted per ENI."
  }
}

# ---------------------------------------------------------------------------
# Test: Instance attachment config accepted per ENI
# ---------------------------------------------------------------------------
run "instance_attachment_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      attached = {
        subnet_id = "subnet-00000000000000000"
        attachment = {
          instance_id  = "i-00000000000000000"
          device_index = 1
        }
      }
    }
  }

  assert {
    condition     = var.network_interfaces["attached"].attachment != null
    error_message = "Instance attachment config should be accepted."
  }

  assert {
    condition     = var.network_interfaces["attached"].attachment.device_index == 1
    error_message = "device_index should be 1 (eth1)."
  }
}

# ---------------------------------------------------------------------------
# Test: Static private IPs accepted per ENI
# ---------------------------------------------------------------------------
run "static_private_ips_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      static = {
        subnet_id    = "subnet-00000000000000000"
        private_ips  = ["10.0.1.100", "10.0.1.101"]
      }
    }
  }

  assert {
    condition     = length(var.network_interfaces["static"].private_ips) == 2
    error_message = "Two static private IPs should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: additional_tags accepted per ENI
# ---------------------------------------------------------------------------
run "additional_tags_per_eni" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      tagged = {
        subnet_id = "subnet-00000000000000000"
        additional_tags = {
          Role = "primary-interface"
        }
      }
    }
  }

  assert {
    condition     = var.network_interfaces["tagged"].additional_tags["Role"] == "primary-interface"
    error_message = "Per-ENI additional_tags should be accepted."
  }
}
