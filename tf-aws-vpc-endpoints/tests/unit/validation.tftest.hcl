# Unit tests — variable validation rules for tf-aws-vpc-endpoints
# Verifies structural correctness and per-endpoint override behavior.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: Per-endpoint subnet_ids override accepted
# ---------------------------------------------------------------------------
run "per_endpoint_subnet_override" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    default_subnet_ids = ["subnet-aaaa0000000000000"]
    endpoints = {
      ssm = {
        service_name      = "com.amazonaws.us-east-1.ssm"
        vpc_endpoint_type = "Interface"
        subnet_ids        = ["subnet-bbbb0000000000000"]  # overrides default
      }
    }
  }

  assert {
    condition     = var.endpoints["ssm"].subnet_ids == ["subnet-bbbb0000000000000"]
    error_message = "Per-endpoint subnet_ids override should take precedence."
  }
}

# ---------------------------------------------------------------------------
# Test: per-endpoint security_group_ids override accepted
# ---------------------------------------------------------------------------
run "per_endpoint_sg_override" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    endpoints = {
      ec2 = {
        service_name       = "com.amazonaws.us-east-1.ec2"
        vpc_endpoint_type  = "Interface"
        security_group_ids = ["sg-00000000000000001"]
      }
    }
  }

  assert {
    condition     = var.endpoints["ec2"].security_group_ids == ["sg-00000000000000001"]
    error_message = "Per-endpoint security_group_ids should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: private_dns can be disabled per endpoint
# ---------------------------------------------------------------------------
run "private_dns_disabled_per_endpoint" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    endpoints = {
      s3_interface = {
        service_name      = "com.amazonaws.us-east-1.s3"
        vpc_endpoint_type = "Interface"
        private_dns       = false
      }
    }
  }

  assert {
    condition     = var.endpoints["s3_interface"].private_dns == false
    error_message = "private_dns should be disableable per endpoint."
  }
}

# ---------------------------------------------------------------------------
# Test: ip_address_type field accepted per endpoint
# ---------------------------------------------------------------------------
run "ip_address_type_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    endpoints = {
      ssm = {
        service_name      = "com.amazonaws.us-east-1.ssm"
        vpc_endpoint_type = "Interface"
        ip_address_type   = "ipv4"
      }
    }
  }

  assert {
    condition     = var.endpoints["ssm"].ip_address_type == "ipv4"
    error_message = "ip_address_type field should be accepted."
  }
}
