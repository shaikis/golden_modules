# Unit tests — defaults and feature gates for tf-aws-eni
# Runs as plan-only; no AWS resources are created.

variables {
  name = "test-eni"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Test: network_interfaces defaults to empty map (no ENIs unless specified)
# ---------------------------------------------------------------------------
run "network_interfaces_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.network_interfaces == {}
    error_message = "network_interfaces should default to an empty map."
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

# ---------------------------------------------------------------------------
# Test: tags default to empty map
# ---------------------------------------------------------------------------
run "tags_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.tags == {}
    error_message = "tags should default to an empty map."
  }
}

# ---------------------------------------------------------------------------
# Test: name_prefix defaults to empty string
# ---------------------------------------------------------------------------
run "name_prefix_default" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.name_prefix == ""
    error_message = "name_prefix should default to empty string."
  }
}

# ---------------------------------------------------------------------------
# Test: Single ENI with minimal config is accepted in plan
# ---------------------------------------------------------------------------
run "single_eni_plan" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      primary = {
        subnet_id         = "subnet-00000000000000000"
        security_group_ids = ["sg-00000000000000000"]
        description       = "Primary ENI for test"
      }
    }
  }

  assert {
    condition     = length(var.network_interfaces) == 1
    error_message = "Expected exactly one ENI definition in the plan."
  }
}

# ---------------------------------------------------------------------------
# Test: source_dest_check defaults to true per ENI
# ---------------------------------------------------------------------------
run "source_dest_check_default_true" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      primary = {
        subnet_id = "subnet-00000000000000000"
      }
    }
  }

  assert {
    condition     = var.network_interfaces["primary"].source_dest_check == true
    error_message = "source_dest_check should default to true."
  }
}

# ---------------------------------------------------------------------------
# Test: source_dest_check can be disabled (for NVA / NAT appliances)
# ---------------------------------------------------------------------------
run "source_dest_check_disabled" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      nva = {
        subnet_id         = "subnet-00000000000000000"
        source_dest_check = false
        description       = "NVA interface — source/dest check disabled"
      }
    }
  }

  assert {
    condition     = var.network_interfaces["nva"].source_dest_check == false
    error_message = "source_dest_check should be disableable for NVA use-cases."
  }
}

# ---------------------------------------------------------------------------
# Test: Multiple ENIs accepted in a single invocation
# ---------------------------------------------------------------------------
run "multiple_enis_plan" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-eni"
    network_interfaces = {
      eni_a = { subnet_id = "subnet-aaaa0000000000000" }
      eni_b = { subnet_id = "subnet-bbbb0000000000000" }
    }
  }

  assert {
    condition     = length(var.network_interfaces) == 2
    error_message = "Expected two ENI definitions to be accepted."
  }
}
