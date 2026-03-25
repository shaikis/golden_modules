# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
#
# WARNING: AWS Transfer Family servers cost ~$0.30/hour while running.
# Destroy promptly after testing to avoid unexpected charges.
#
# Creates a real SFTP PUBLIC Transfer server and asserts the server_id output.
# Requires valid AWS credentials and IAM permissions for transfer:CreateServer.

run "create_sftp_public_server_and_assert_id" {
  command = apply

  variables {
    create_users      = false
    create_ssh_keys   = false
    create_workflows  = false
    create_connectors = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"
    kms_key_arn       = null

    servers = {
      test_sftp = {
        endpoint_type = "PUBLIC"
        protocols     = ["SFTP"]

        tags = {
          Environment = "test"
          ManagedBy   = "terraform-test"
        }
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

  # Assert that a server ID was produced in module outputs.
  assert {
    condition     = length(keys(module.server_ids)) > 0
    error_message = "Expected at least one Transfer server ID in module outputs but got none."
  }
}
