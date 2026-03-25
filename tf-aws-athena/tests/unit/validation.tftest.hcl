# Unit tests — tf-aws-athena variable validation
# command = plan: no real AWS resources are created.
# Each run block that tests a rejection must set expect_failures.

run "valid_workgroup_state_enabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    workgroups = {
      valid_wg = {
        state = "ENABLED"
      }
    }
  }

  # A valid state should not fail.
  assert {
    condition     = var.workgroups["valid_wg"].state == "ENABLED"
    error_message = "Expected workgroup state ENABLED to be accepted."
  }
}

run "valid_workgroup_state_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    workgroups = {
      disabled_wg = {
        state = "DISABLED"
      }
    }
  }

  assert {
    condition     = var.workgroups["disabled_wg"].state == "DISABLED"
    error_message = "Expected workgroup state DISABLED to be accepted."
  }
}

run "workgroup_engine_version_auto_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    workgroups = {
      wg = {}
    }
  }

  assert {
    condition     = var.workgroups["wg"].engine_version == "AUTO"
    error_message = "Expected engine_version to default to AUTO."
  }
}

run "workgroup_enforce_configuration_default_true" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    workgroups = {
      wg = {}
    }
  }

  assert {
    condition     = var.workgroups["wg"].enforce_workgroup_configuration == true
    error_message = "Expected enforce_workgroup_configuration to default to true."
  }
}

run "name_prefix_accepts_empty_string" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name_prefix = ""
  }

  assert {
    condition     = var.name_prefix == ""
    error_message = "Expected name_prefix to accept an empty string."
  }
}

run "tags_accepts_non_empty_map" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    tags = {
      Environment = "test"
      Team        = "data"
    }
  }

  assert {
    condition     = var.tags["Environment"] == "test"
    error_message = "Expected tags map to be accepted with string values."
  }
}
