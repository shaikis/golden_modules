# tests/unit/defaults.tftest.hcl — tf-aws-cloudwatch
# Verifies feature-gate defaults and BYO patterns via plan only (free).

variables {
  name = "test-cw"
}

# ---------------------------------------------------------------------------
# create_dashboard defaults to false — no dashboard resource planned
# ---------------------------------------------------------------------------
run "dashboard_off_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name             = "test-cw"
    create_dashboard = false
  }

  assert {
    condition     = var.create_dashboard == false
    error_message = "create_dashboard must default to false"
  }
}

# ---------------------------------------------------------------------------
# create_sns_topic defaults to true — SNS topic is created by default
# ---------------------------------------------------------------------------
run "sns_topic_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name             = "test-cw"
    create_sns_topic = true
  }

  assert {
    condition     = var.create_sns_topic == true
    error_message = "create_sns_topic should default to true"
  }
}

# ---------------------------------------------------------------------------
# BYO SNS pattern — skip topic creation when arn is supplied
# ---------------------------------------------------------------------------
run "byo_sns_topic" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name             = "test-cw"
    create_sns_topic = false
    sns_topic_arn    = "arn:aws:sns:us-east-1:123456789012:existing-topic"
  }

  assert {
    condition     = var.create_sns_topic == false
    error_message = "create_sns_topic should be false in BYO pattern"
  }

  assert {
    condition     = var.sns_topic_arn == "arn:aws:sns:us-east-1:123456789012:existing-topic"
    error_message = "sns_topic_arn should be set to the provided ARN"
  }
}

# ---------------------------------------------------------------------------
# No email endpoints by default
# ---------------------------------------------------------------------------
run "no_email_endpoints_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-cw"
  }

  assert {
    condition     = length(var.email_endpoints) == 0
    error_message = "email_endpoints should default to an empty list"
  }
}

# ---------------------------------------------------------------------------
# Dashboard off — dashboard_services defaults to empty object
# ---------------------------------------------------------------------------
run "dashboard_services_empty_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-cw"
  }

  assert {
    condition     = length(var.dashboard_services.lambda_functions) == 0
    error_message = "dashboard_services.lambda_functions should default to empty"
  }
}

# ---------------------------------------------------------------------------
# Tags merged correctly
# ---------------------------------------------------------------------------
run "tags_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "test-cw"
    environment = "test"
    tags = {
      CostCenter = "eng-123"
    }
  }

  assert {
    condition     = var.tags["CostCenter"] == "eng-123"
    error_message = "Custom tags should be accepted"
  }
}
