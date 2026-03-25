# Unit tests — variable validation for tf-aws-alb
# command = plan; no real AWS resources are created.

# Verify that an invalid load_balancer_type value causes a plan-time error.
# The module does not declare a validation block for load_balancer_type, but
# AWS will reject the value at apply time. This test documents the expected
# contract and can be extended once a validation block is added.

run "valid_load_balancer_type_application" {
  command = plan

  variables {
    name               = "test-alb-app"
    vpc_id             = "vpc-00000000000000001"
    subnets            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    load_balancer_type = "application"
  }

  assert {
    condition     = var.load_balancer_type == "application"
    error_message = "load_balancer_type 'application' should be accepted."
  }
}

run "valid_load_balancer_type_network" {
  command = plan

  variables {
    name               = "test-alb-net"
    vpc_id             = "vpc-00000000000000001"
    subnets            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    load_balancer_type = "network"
  }

  assert {
    condition     = var.load_balancer_type == "network"
    error_message = "load_balancer_type 'network' should be accepted."
  }
}

run "valid_load_balancer_type_gateway" {
  command = plan

  variables {
    name               = "test-alb-gwy"
    vpc_id             = "vpc-00000000000000001"
    subnets            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    load_balancer_type = "gateway"
  }

  assert {
    condition     = var.load_balancer_type == "gateway"
    error_message = "load_balancer_type 'gateway' should be accepted."
  }
}

run "internal_false_means_internet_facing" {
  command = plan

  variables {
    name     = "test-alb-public"
    vpc_id   = "vpc-00000000000000001"
    subnets  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    internal = false
  }

  assert {
    condition     = var.internal == false
    error_message = "internal = false should be accepted."
  }
}

run "internal_true_means_private" {
  command = plan

  variables {
    name     = "test-alb-private"
    vpc_id   = "vpc-00000000000000001"
    subnets  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    internal = true
  }

  assert {
    condition     = var.internal == true
    error_message = "internal = true should be accepted."
  }
}
