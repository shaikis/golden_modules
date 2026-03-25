# tests/integration/basic.tftest.hcl — tf-aws-route53
# Creates a real public hosted zone, verifies outputs, then destroys.
# Requires valid AWS credentials with Route 53 permissions.
# SKIP_IN_CI

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "test-r53"
  environment = "test"
  tags = {
    ManagedBy = "terraform-test"
    Module    = "tf-aws-route53"
  }
}

# ---------------------------------------------------------------------------
# Apply — create a minimal public hosted zone
# ---------------------------------------------------------------------------
run "create_public_zone" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name = "test-r53"
    zones = {
      main = {
        name          = "tftest-example-terraform.com"
        comment       = "Created by terraform test"
        force_destroy = true
      }
    }
    tags = {
      ManagedBy = "terraform-test"
    }
  }

  assert {
    condition     = length(output.zone_ids) > 0
    error_message = "zone_ids output must contain at least one entry"
  }

  assert {
    condition     = length(output.zone_name_servers) > 0
    error_message = "zone_name_servers output must be populated"
  }
}
