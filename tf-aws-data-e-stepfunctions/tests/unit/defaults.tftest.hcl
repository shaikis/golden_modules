# tests/unit/defaults.tftest.hcl
# Verifies that the module plans successfully with create_activities=false,
# create_alarms=false, and a BYO role_arn — no real resources created.

run "defaults_no_resources" {
  command = plan

  variables {
    create_activities = false
    create_alarms     = false
    create_iam_role   = false
    role_arn          = "arn:aws:iam::123456789012:role/test"
    state_machines    = {}
    activities        = {}
    tags              = {}
  }

  module {
    source = "../../"
  }
}
