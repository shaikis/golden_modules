# tests/unit/defaults.tftest.hcl
# Verifies that the module plans successfully with all create_X gates disabled
# and a BYO role_arn, producing no real resources.

run "defaults_no_resources" {
  command = plan

  variables {
    create_custom_buses      = false
    create_api_connections   = false
    create_api_destinations  = false
    create_archives          = false
    create_pipes             = false
    create_schema_registries = false
    create_alarms            = false
    create_iam_role          = false
    role_arn                 = "arn:aws:iam::123456789012:role/test"
    event_buses              = {}
    rules                    = {}
    targets                  = {}
    tags                     = {}
  }

  module {
    source = "../../"
  }
}
