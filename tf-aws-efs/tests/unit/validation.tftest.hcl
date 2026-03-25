# Unit tests — variable validation for tf-aws-efs
# command = plan; no real AWS resources are created.

run "valid_throughput_mode_elastic" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    throughput_mode       = "elastic"
  }

  assert {
    condition     = var.throughput_mode == "elastic"
    error_message = "throughput_mode 'elastic' should be accepted."
  }
}

run "valid_throughput_mode_bursting" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    throughput_mode       = "bursting"
  }

  assert {
    condition     = var.throughput_mode == "bursting"
    error_message = "throughput_mode 'bursting' should be accepted."
  }
}

run "valid_throughput_mode_provisioned" {
  command = plan

  variables {
    name                           = "efs-test"
    environment                    = "dev"
    create_security_group          = false
    throughput_mode                = "provisioned"
    provisioned_throughput_in_mibps = 100
  }

  assert {
    condition     = var.throughput_mode == "provisioned"
    error_message = "throughput_mode 'provisioned' should be accepted."
  }
}

run "valid_performance_mode_general_purpose" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    performance_mode      = "generalPurpose"
  }

  assert {
    condition     = var.performance_mode == "generalPurpose"
    error_message = "performance_mode 'generalPurpose' should be accepted."
  }
}

run "valid_performance_mode_max_io" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    performance_mode      = "maxIO"
  }

  assert {
    condition     = var.performance_mode == "maxIO"
    error_message = "performance_mode 'maxIO' should be accepted."
  }
}

# Negative test: invalid throughput_mode must be rejected by the validation block.
run "invalid_throughput_mode_rejected" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    throughput_mode       = "turbo"
  }

  expect_failures = [
    var.throughput_mode,
  ]
}

# Negative test: invalid performance_mode must be rejected.
run "invalid_performance_mode_rejected" {
  command = plan

  variables {
    name                  = "efs-test"
    environment           = "dev"
    create_security_group = false
    performance_mode      = "superfast"
  }

  expect_failures = [
    var.performance_mode,
  ]
}
