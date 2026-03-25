# tests/integration/basic.tftest.hcl — tf-aws-sns
# Creates a minimal SNS topic, verifies outputs, then destroys.
# Requires valid AWS credentials with SNS permissions.
# SKIP_IN_CI

provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "tftest-sns-basic"
  environment = "test"
  tags = {
    ManagedBy = "terraform-test"
    Module    = "tf-aws-sns"
  }
}

# ---------------------------------------------------------------------------
# Apply — create a minimal standard SNS topic
# ---------------------------------------------------------------------------
run "create_standard_topic" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name = "tftest-sns-basic"
    tags = {
      ManagedBy = "terraform-test"
    }
  }

  assert {
    condition     = output.topic_arn != ""
    error_message = "topic_arn output must be non-empty after apply"
  }
}

# ---------------------------------------------------------------------------
# Apply — create a FIFO topic
# ---------------------------------------------------------------------------
run "create_fifo_topic" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name                        = "tftest-sns-fifo.fifo"
    fifo_topic                  = true
    content_based_deduplication = true
    tags = {
      ManagedBy = "terraform-test"
    }
  }

  assert {
    condition     = output.topic_arn != ""
    error_message = "FIFO topic_arn must be non-empty after apply"
  }
}
