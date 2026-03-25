# tests/integration/basic.tftest.hcl — tf-aws-cloudwatch
# Creates minimal real AWS resources, verifies outputs, then destroys.
# Requires valid AWS credentials and permissions for CloudWatch + SNS.
# SKIP_IN_CI

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest-cw-basic"
  environment = "test"
  tags = {
    ManagedBy = "terraform-test"
    Module    = "tf-aws-cloudwatch"
  }
}

# ---------------------------------------------------------------------------
# Apply — create SNS topic only (all other gates remain off)
# ---------------------------------------------------------------------------
run "create_sns_topic_only" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name             = "tftest-cw-basic"
    create_sns_topic = true
    create_dashboard = false
  }

  assert {
    condition     = output.sns_topic_arn != ""
    error_message = "sns_topic_arn output must be non-empty after apply"
  }
}

# ---------------------------------------------------------------------------
# Apply — enable dashboard after topic already exists
# ---------------------------------------------------------------------------
run "enable_dashboard" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name             = "tftest-cw-basic"
    create_sns_topic = true
    create_dashboard = true
    dashboard_services = {
      lambda_functions = []
      sqs_queues       = []
    }
  }

  assert {
    condition     = output.dashboard_name != null
    error_message = "dashboard_name output should be set when create_dashboard = true"
  }
}
