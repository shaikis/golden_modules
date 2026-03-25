# Integration tests — tf-aws-ecr
# Cost estimate: $0.00 — ECR repositories have no hourly charge; storage ~$0.10/GB/month.
# These tests CREATE real ECR repositories. Remember to run terraform destroy after.
# Run manually: terraform test -filter=tests/integration

# ── Test 1: Create a single ECR repository and verify outputs ────────────────
# SKIP_IN_CI
run "create_single_ecr_repo" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-ecr"
    environment = "test"
    repositories = {
      "app" = {
        image_tag_mutability = "MUTABLE"
        scan_on_push         = true
        force_delete         = true
        encryption_type      = "AES256"
      }
    }
  }

  assert {
    condition     = length(output.repository_urls) == 1
    error_message = "Expected exactly one repository URL."
  }

  assert {
    condition     = length(output.repository_urls["app"]) > 0
    error_message = "repository_url for 'app' must be non-empty."
  }

  assert {
    condition     = length(output.repository_arns["app"]) > 0
    error_message = "repository_arn for 'app' must be non-empty."
  }

  assert {
    condition     = output.registry_id != ""
    error_message = "registry_id output must be non-empty."
  }
}

# ── Test 2: Create multiple repositories ────────────────────────────────────
# SKIP_IN_CI
run "create_multiple_ecr_repos" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name        = "tftest-ecr-multi"
    environment = "test"
    repositories = {
      "frontend" = {
        image_tag_mutability = "MUTABLE"
        scan_on_push         = false
        force_delete         = true
        encryption_type      = "AES256"
      }
      "backend" = {
        image_tag_mutability = "IMMUTABLE"
        scan_on_push         = true
        force_delete         = true
        encryption_type      = "AES256"
      }
    }
  }

  assert {
    condition     = length(output.repository_urls) == 2
    error_message = "Expected exactly two repository URLs."
  }

  assert {
    condition     = contains(keys(output.repository_urls), "frontend")
    error_message = "repository_urls must contain 'frontend' key."
  }

  assert {
    condition     = contains(keys(output.repository_urls), "backend")
    error_message = "repository_urls must contain 'backend' key."
  }
}
