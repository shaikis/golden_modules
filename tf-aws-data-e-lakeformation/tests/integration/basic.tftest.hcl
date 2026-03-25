# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
# Registers a real S3 location with Lake Formation and asserts the output.
# Requires valid AWS credentials, an existing S3 bucket ARN, and an IAM role
# with lakeformation:RegisterResource permission.

run "register_s3_location_and_assert_output" {
  command = apply

  variables {
    create_permissions     = false
    create_lf_tags         = false
    create_data_filters    = false
    create_governed_tables = false
    create_iam_role        = false
    role_arn               = "arn:aws:iam::123456789012:role/test"

    data_lake_locations = {
      test_location = {
        s3_arn                  = "arn:aws:s3:::my-test-datalake-bucket"
        use_service_linked_role = true
        hybrid_access_enabled   = false
      }
    }

    tags = {
      Environment = "test"
      ManagedBy   = "terraform-test"
    }
  }

  module {
    source = "../../"
  }

  # Assert that the registered location ARN appears in module outputs.
  assert {
    condition     = length(keys(module.data_lake_location_arns)) > 0
    error_message = "Expected at least one data lake location ARN in module outputs but got none."
  }
}
