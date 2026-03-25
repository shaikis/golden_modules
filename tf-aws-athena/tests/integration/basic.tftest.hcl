# Integration tests — tf-aws-athena basic
# command = apply: REAL AWS resources are created, then destroyed.
# Workgroups are free-tier resources but require valid AWS credentials.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

# SKIP_IN_CI
run "create_single_workgroup" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
    workgroups = {
      basic = {
        description = "Integration test workgroup"
        state       = "ENABLED"
        force_destroy = true
      }
    }
  }

  assert {
    condition     = length(var.workgroups) == 1
    error_message = "Expected exactly one workgroup to be configured."
  }
}

# SKIP_IN_CI
run "workgroup_with_result_configuration" {
  command = apply

  module {
    source = "../../"
  }

  variables {
    name_prefix = "tftest-results"
    tags = {
      Environment = "test"
    }
    workgroups = {
      with_results = {
        description   = "Workgroup with result location"
        state         = "ENABLED"
        force_destroy = true
        result_configuration = {
          output_location = "s3://my-athena-results-bucket/output/"
          encryption_type = "SSE_S3"
        }
      }
    }
  }

  assert {
    condition     = var.workgroups["with_results"].result_configuration.encryption_type == "SSE_S3"
    error_message = "Expected result configuration to be accepted with SSE_S3."
  }
}
