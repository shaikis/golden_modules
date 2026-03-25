# Unit tests — tf-aws-ses variable validation
# command = plan: no real AWS resources are created.

run "receipt_rules_disabled_no_rule_set_name_ok" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_receipt_rules = false
    receipt_rules        = {}
  }

  # Receipt rules disabled with no rules defined — should plan cleanly.
  assert {
    condition     = var.create_receipt_rules == false
    error_message = "Expected create_receipt_rules=false with empty rules to be valid."
  }
}

run "email_identity_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    email_identities = {
      test_user = {
        email_address = "test@example.com"
      }
    }
  }

  assert {
    condition     = var.email_identities["test_user"].email_address == "test@example.com"
    error_message = "Expected email identity to be accepted with a valid email address."
  }
}

run "domain_identity_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    domain_identities = {
      my_domain = {
        domain       = "example.com"
        dkim_signing = true
      }
    }
  }

  assert {
    condition     = var.domain_identities["my_domain"].domain == "example.com"
    error_message = "Expected domain identity to be accepted."
  }

  assert {
    condition     = var.domain_identities["my_domain"].dkim_signing == true
    error_message = "Expected dkim_signing = true to be accepted."
  }
}

run "configuration_set_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_configuration_sets = true
    configuration_sets = {
      transactional = {
        sending_enabled            = true
        reputation_metrics_enabled = true
      }
    }
  }

  assert {
    condition     = length(var.configuration_sets) == 1
    error_message = "Expected one configuration set to be accepted."
  }
}

run "template_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_templates = true
    templates = {
      welcome = {
        subject   = "Welcome to our service"
        html_part = "<h1>Welcome!</h1>"
        text_part = "Welcome!"
      }
    }
  }

  assert {
    condition     = var.templates["welcome"].subject == "Welcome to our service"
    error_message = "Expected email template to be accepted with required fields."
  }
}

run "rule_set_with_receipt_rules_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_receipt_rules = true
    rule_sets = {
      main = {
        active = true
      }
    }
    receipt_rules = {
      forward_to_s3 = {
        rule_set_name = "main"
        recipients    = ["info@example.com"]
        s3_actions = [
          {
            bucket_name = "my-mail-bucket"
            position    = 1
          }
        ]
      }
    }
  }

  assert {
    condition     = var.receipt_rules["forward_to_s3"].rule_set_name == "main"
    error_message = "Expected receipt rule with rule_set_name to be accepted."
  }
}
