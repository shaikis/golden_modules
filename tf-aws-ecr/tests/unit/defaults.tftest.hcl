# Unit tests — defaults and feature gates for tf-aws-ecr
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  name = "test-ecr"
}

provider "aws" {
  region                      = "us-east-1"
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
# repositories empty by default (no repos created without explicit config)
# ---------------------------------------------------------------------------
run "repositories_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.repositories) == 0
    error_message = "repositories must default to empty map — no repos created without config."
  }
}

# ---------------------------------------------------------------------------
# enable_replication defaults to false
# ---------------------------------------------------------------------------
run "replication_disabled_by_default" {
  command = plan

  assert {
    condition     = var.enable_replication == false
    error_message = "enable_replication (create_replication_configuration) must default to false."
  }
}

# ---------------------------------------------------------------------------
# scan_on_push defaults to true inside repository objects
# ---------------------------------------------------------------------------
run "scan_on_push_default_true" {
  command = plan

  variables {
    name = "test-ecr-scan"
    repositories = {
      app = {}
    }
  }

  assert {
    condition     = var.repositories["app"].scan_on_push == true
    error_message = "scan_on_push (enable_image_scanning) must default to true."
  }
}

# ---------------------------------------------------------------------------
# image_tag_mutability defaults to IMMUTABLE (security best-practice)
# ---------------------------------------------------------------------------
run "image_tag_immutable_by_default" {
  command = plan

  variables {
    name = "test-ecr-immutable"
    repositories = {
      app = {}
    }
  }

  assert {
    condition     = var.repositories["app"].image_tag_mutability == "IMMUTABLE"
    error_message = "image_tag_mutability must default to IMMUTABLE."
  }
}

# ---------------------------------------------------------------------------
# lifecycle policy: built-in defaults for untagged_image_count
# ---------------------------------------------------------------------------
run "lifecycle_policy_untagged_count_default" {
  command = plan

  assert {
    condition     = var.untagged_image_count == 5
    error_message = "untagged_image_count must default to 5."
  }
}

# ---------------------------------------------------------------------------
# lifecycle policy: built-in defaults for tagged_image_count
# ---------------------------------------------------------------------------
run "lifecycle_policy_tagged_count_default" {
  command = plan

  assert {
    condition     = var.tagged_image_count == 30
    error_message = "tagged_image_count must default to 30."
  }
}

# ---------------------------------------------------------------------------
# cross_account_ids defaults to empty (no cross-account pull by default)
# ---------------------------------------------------------------------------
run "cross_account_ids_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.cross_account_ids) == 0
    error_message = "cross_account_ids must default to empty list."
  }
}

# ---------------------------------------------------------------------------
# Replication gate: enable_replication = true accepted
# ---------------------------------------------------------------------------
run "replication_gate_enabled" {
  command = plan

  variables {
    name               = "test-ecr-repl"
    enable_replication = true
    replication_destinations = [
      {
        region      = "us-west-2"
        registry_id = "123456789012"
      }
    ]
  }

  assert {
    condition     = var.enable_replication == true
    error_message = "enable_replication gate must accept true."
  }
}
