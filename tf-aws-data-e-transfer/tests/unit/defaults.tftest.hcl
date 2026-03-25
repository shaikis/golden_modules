# tests/unit/defaults.tftest.hcl
# Verifies that the module plans successfully with all optional gates disabled
# and BYO role/kms references — no real resources created.

run "defaults_no_resources" {
  command = plan

  variables {
    create_users      = false
    create_ssh_keys   = false
    create_workflows  = false
    create_connectors = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"
    kms_key_arn       = null
    servers           = {}
    tags              = {}
  }

  module {
    source = "../../"
  }
}
