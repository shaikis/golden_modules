# Unit tests — defaults and feature gates for tf-aws-vpc-endpoints
# Runs as plan-only; no AWS resources are created.

variables {
  name   = "test-endpoints"
  vpc_id = "vpc-00000000000000000"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: endpoints map defaults to empty (no endpoints created unless specified)
# ---------------------------------------------------------------------------
run "endpoints_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.endpoints == {}
    error_message = "endpoints should default to an empty map — no endpoints unless specified."
  }
}

# ---------------------------------------------------------------------------
# Test: default_subnet_ids defaults to empty list
# ---------------------------------------------------------------------------
run "default_subnet_ids_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.default_subnet_ids == []
    error_message = "default_subnet_ids should default to an empty list."
  }
}

# ---------------------------------------------------------------------------
# Test: default_security_group_ids defaults to empty list
# ---------------------------------------------------------------------------
run "default_security_group_ids_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.default_security_group_ids == []
    error_message = "default_security_group_ids should default to an empty list."
  }
}

# ---------------------------------------------------------------------------
# Test: default_route_table_ids defaults to empty list
# ---------------------------------------------------------------------------
run "default_route_table_ids_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.default_route_table_ids == []
    error_message = "default_route_table_ids should default to an empty list."
  }
}

# ---------------------------------------------------------------------------
# Test: Gateway endpoint type accepted in endpoints map
# ---------------------------------------------------------------------------
run "gateway_endpoint_type_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    endpoints = {
      s3 = {
        service_name      = "com.amazonaws.us-east-1.s3"
        vpc_endpoint_type = "Gateway"
        route_table_ids   = []
      }
    }
  }

  assert {
    condition     = var.endpoints["s3"].vpc_endpoint_type == "Gateway"
    error_message = "Gateway endpoint type should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Interface endpoint type accepted in endpoints map
# ---------------------------------------------------------------------------
run "interface_endpoint_type_accepted" {
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
        private_dns       = true
      }
    }
  }

  assert {
    condition     = var.endpoints["ssm"].vpc_endpoint_type == "Interface"
    error_message = "Interface endpoint type should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Multiple endpoints accepted in a single invocation
# ---------------------------------------------------------------------------
run "multiple_endpoints_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name   = "test-endpoints"
    vpc_id = "vpc-00000000000000000"
    endpoints = {
      s3 = {
        service_name      = "com.amazonaws.us-east-1.s3"
        vpc_endpoint_type = "Gateway"
      }
      ec2 = {
        service_name      = "com.amazonaws.us-east-1.ec2"
        vpc_endpoint_type = "Interface"
      }
      ssm = {
        service_name      = "com.amazonaws.us-east-1.ssm"
        vpc_endpoint_type = "Interface"
      }
    }
  }

  assert {
    condition     = length(var.endpoints) == 3
    error_message = "Expected three endpoints in the map."
  }
}

# ---------------------------------------------------------------------------
# Test: environment defaults to dev
# ---------------------------------------------------------------------------
run "environment_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "environment should default to 'dev'."
  }
}
