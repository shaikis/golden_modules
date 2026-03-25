# tests/unit/validation.tftest.hcl
# Verifies that invalid endpoint_type and protocol values are rejected by
# module input validation.

run "invalid_endpoint_type_rejected" {
  command = plan

  variables {
    create_users      = false
    create_ssh_keys   = false
    create_workflows  = false
    create_connectors = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"

    servers = {
      bad_endpoint = {
        # Must be PUBLIC, VPC, or VPC_ENDPOINT — this should be rejected.
        endpoint_type = "INVALID_ENDPOINT"
        protocols     = ["SFTP"]
      }
    }
  }

  module {
    source = "../../"
  }

  expect_failures = [
    var.servers,
  ]
}

run "invalid_protocol_rejected" {
  command = plan

  variables {
    create_users      = false
    create_ssh_keys   = false
    create_workflows  = false
    create_connectors = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"

    servers = {
      bad_protocol = {
        endpoint_type = "PUBLIC"
        # INVALID protocol — valid values are SFTP, FTP, FTPS, AS2.
        protocols = ["INVALID_PROTO"]
      }
    }
  }

  module {
    source = "../../"
  }

  expect_failures = [
    var.servers,
  ]
}
