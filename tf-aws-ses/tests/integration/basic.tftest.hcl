# Integration tests — tf-aws-ses basic
# command = apply: REAL AWS resources are created, then destroyed.
# Creating an email identity is free but sends a verification email.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "create_email_identity" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    email_identities = {
      test_sender = {
        email_address = "no-reply@example.com"
      }
    }
  }

  assert {
    condition     = length(var.email_identities) == 1
    error_message = "Expected exactly one email identity to be configured."
  }

  assert {
    condition     = var.email_identities["test_sender"].email_address == "no-reply@example.com"
    error_message = "Expected email_address to match the supplied value."
  }
}

# SKIP_IN_CI
run "create_email_identity_with_configuration_set" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    tags = {
      Environment = "test"
    }
    create_configuration_sets = true
    configuration_sets = {
      transactional = {
        sending_enabled            = true
        reputation_metrics_enabled = true
        suppression_reasons        = ["BOUNCE", "COMPLAINT"]
      }
    }
    email_identities = {
      transactional_sender = {
        email_address          = "notify@example.com"
        configuration_set_name = "transactional"
      }
    }
  }

  assert {
    condition     = var.email_identities["transactional_sender"].configuration_set_name == "transactional"
    error_message = "Expected email identity to reference the transactional configuration set."
  }

  assert {
    condition     = length(var.configuration_sets) == 1
    error_message = "Expected one configuration set to be configured."
  }
}
