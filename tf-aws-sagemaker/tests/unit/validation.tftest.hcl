# Unit tests — input validation rules
# All runs use command = plan with expect_failures to confirm that
# bad inputs are rejected at plan time before any AWS API calls.
# No AWS credentials required.

# ---------------------------------------------------------------------------
# Test 1: Invalid domain auth_mode is rejected
#         Allowed values: "IAM" | "SSO"
# ---------------------------------------------------------------------------
run "invalid_domain_auth_mode_rejected" {
  command = plan

  expect_failures = [var.domains]

  variables {
    create_domains = true
    domains = {
      "bad-auth" = {
        auth_mode  = "SAML"        # invalid — not IAM or SSO
        vpc_id     = "vpc-0abc123"
        subnet_ids = ["subnet-0abc123"]
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Test 2: Valid domain auth_mode values are accepted (positive control)
# ---------------------------------------------------------------------------
run "valid_domain_auth_mode_iam_accepted" {
  command = plan

  variables {
    create_domains = true
    domains = {
      "studio" = {
        auth_mode  = "IAM"
        vpc_id     = "vpc-0abc123"
        subnet_ids = ["subnet-0abc123"]
      }
    }
  }

  assert {
    condition     = var.domains["studio"].auth_mode == "IAM"
    error_message = "auth_mode 'IAM' should be accepted."
  }
}

run "valid_domain_auth_mode_sso_accepted" {
  command = plan

  variables {
    create_domains = true
    domains = {
      "studio-sso" = {
        auth_mode  = "SSO"
        vpc_id     = "vpc-0abc123"
        subnet_ids = ["subnet-0abc123"]
      }
    }
  }

  assert {
    condition     = var.domains["studio-sso"].auth_mode == "SSO"
    error_message = "auth_mode 'SSO' should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test 3: Invalid domain app_network_access_type is rejected
#         Allowed values: "PublicInternetOnly" | "VpcOnly"
# ---------------------------------------------------------------------------
run "invalid_app_network_access_type_rejected" {
  command = plan

  expect_failures = [var.domains]

  variables {
    create_domains = true
    domains = {
      "bad-network" = {
        auth_mode               = "IAM"
        vpc_id                  = "vpc-0abc123"
        subnet_ids              = ["subnet-0abc123"]
        app_network_access_type = "Private"  # invalid
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Test 4: Notebook instance_type not starting with "ml." is rejected
# ---------------------------------------------------------------------------
run "invalid_notebook_instance_type_rejected" {
  command = plan

  expect_failures = [var.notebooks]

  variables {
    create_notebooks = true
    notebooks = {
      "bad-type" = {
        instance_type = "t3.medium"  # invalid — must start with ml.
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Test 5: Valid notebook instance_type is accepted (positive control)
# ---------------------------------------------------------------------------
run "valid_notebook_instance_type_accepted" {
  command = plan

  variables {
    create_notebooks = true
    notebooks = {
      "good-type" = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  assert {
    condition     = var.notebooks["good-type"].instance_type == "ml.t3.medium"
    error_message = "instance_type 'ml.t3.medium' should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test 6: Invalid feature_type in feature_groups is rejected
#         Allowed values: "Integral" | "Fractional" | "String"
# ---------------------------------------------------------------------------
run "invalid_feature_type_rejected" {
  command = plan

  expect_failures = [var.feature_groups]

  variables {
    create_feature_groups = true
    feature_groups = {
      "bad-features" = {
        record_identifier_name  = "id"
        event_time_feature_name = "event_time"
        features = [
          {
            name         = "id"
            feature_type = "String"
          },
          {
            name         = "event_time"
            feature_type = "String"
          },
          {
            name         = "score"
            feature_type = "Float"  # invalid — should be Fractional
          }
        ]
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Test 7: All valid feature_type values are accepted (positive control)
# ---------------------------------------------------------------------------
run "valid_feature_types_accepted" {
  command = plan

  variables {
    create_feature_groups = true
    feature_groups = {
      "good-features" = {
        record_identifier_name  = "customer_id"
        event_time_feature_name = "event_time"
        features = [
          { name = "customer_id",    feature_type = "String"     },
          { name = "event_time",     feature_type = "String"     },
          { name = "age",            feature_type = "Integral"   },
          { name = "ltv",            feature_type = "Fractional" }
        ]
      }
    }
  }

  assert {
    condition     = length(var.feature_groups["good-features"].features) == 4
    error_message = "All four features with valid types should be accepted."
  }
}
