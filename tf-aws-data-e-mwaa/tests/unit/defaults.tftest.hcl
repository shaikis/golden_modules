# tests/unit/defaults.tftest.hcl
# Verifies that the module plans successfully with create_alarms=false
# and a BYO execution role, producing no alarm resources.

run "defaults_no_alarms_byo_role" {
  command = plan

  variables {
    create_alarms   = false
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test"
    environments    = {}
    tags            = {}
  }

  module {
    source = "../../"
  }
}
