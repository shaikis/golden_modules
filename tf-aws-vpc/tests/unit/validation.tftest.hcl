# Unit tests — variable validation rules for tf-aws-vpc
# Each run block expects a plan failure when an invalid value is provided.

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: instance_tenancy rejects invalid values
# ---------------------------------------------------------------------------
run "instance_tenancy_rejects_invalid" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-vpc"
    cidr_block         = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    instance_tenancy   = "host"
  }

  expect_failures = [
    var.instance_tenancy,
  ]
}

# ---------------------------------------------------------------------------
# Test: instance_tenancy accepts 'default'
# ---------------------------------------------------------------------------
run "instance_tenancy_accepts_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-vpc"
    cidr_block         = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    instance_tenancy   = "default"
  }

  assert {
    condition     = var.instance_tenancy == "default"
    error_message = "instance_tenancy 'default' should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: instance_tenancy accepts 'dedicated'
# ---------------------------------------------------------------------------
run "instance_tenancy_accepts_dedicated" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name               = "test-vpc"
    cidr_block         = "10.0.0.0/16"
    availability_zones = ["us-east-1a"]
    instance_tenancy   = "dedicated"
  }

  assert {
    condition     = var.instance_tenancy == "dedicated"
    error_message = "instance_tenancy 'dedicated' should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: flow_log_destination_type rejects invalid values
# ---------------------------------------------------------------------------
run "flow_log_destination_type_rejects_invalid" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                      = "test-vpc"
    cidr_block                = "10.0.0.0/16"
    availability_zones        = ["us-east-1a"]
    flow_log_destination_type = "kinesis"
  }

  expect_failures = [
    var.flow_log_destination_type,
  ]
}

# ---------------------------------------------------------------------------
# Test: flow_log_destination_type accepts 'cloud-watch-logs'
# ---------------------------------------------------------------------------
run "flow_log_destination_type_accepts_cloudwatch" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                      = "test-vpc"
    cidr_block                = "10.0.0.0/16"
    availability_zones        = ["us-east-1a"]
    flow_log_destination_type = "cloud-watch-logs"
  }

  assert {
    condition     = var.flow_log_destination_type == "cloud-watch-logs"
    error_message = "flow_log_destination_type 'cloud-watch-logs' should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: flow_log_destination_type accepts 's3'
# ---------------------------------------------------------------------------
run "flow_log_destination_type_accepts_s3" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                      = "test-vpc"
    cidr_block                = "10.0.0.0/16"
    availability_zones        = ["us-east-1a"]
    enable_flow_log           = false
    flow_log_destination_type = "s3"
  }

  assert {
    condition     = var.flow_log_destination_type == "s3"
    error_message = "flow_log_destination_type 's3' should be accepted."
  }
}
