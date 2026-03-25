# tests/integration/basic.tftest.hcl — tf-aws-secretsmanager
# Creates a minimal secret, verifies outputs, then destroys.
# Requires valid AWS credentials with Secrets Manager permissions.
# SKIP_IN_CI

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest/secretsmanager/basic"
  environment = "test"
  tags = {
    ManagedBy = "terraform-test"
    Module    = "tf-aws-secretsmanager"
  }
}

# ---------------------------------------------------------------------------
# Apply — create a minimal secret with plain string value
# ---------------------------------------------------------------------------
run "create_minimal_secret" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                  = "tftest/secretsmanager/basic"
    secret_string         = "terraform-test-value-do-not-use"
    description           = "Integration test secret — safe to delete"
    recovery_window_days  = 0
    tags = {
      ManagedBy = "terraform-test"
    }
  }

  assert {
    condition     = output.secret_arn != ""
    error_message = "secret_arn output must be non-empty after apply"
  }

  assert {
    condition     = output.secret_id != ""
    error_message = "secret_id output must be non-empty after apply"
  }
}

# ---------------------------------------------------------------------------
# Apply — BYO KMS key passed via variable
# ---------------------------------------------------------------------------
run "secret_with_byo_kms" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                  = "tftest/secretsmanager/byo-kms"
    secret_string         = "terraform-test-kms-value"
    description           = "Integration test secret with BYO KMS — safe to delete"
    kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abc"
    recovery_window_days  = 0
  }
}
