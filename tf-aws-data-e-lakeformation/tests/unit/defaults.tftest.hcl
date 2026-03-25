# tests/unit/defaults.tftest.hcl
# Verifies that the module plans successfully with all create_X gates disabled
# and a BYO role_arn, producing no real resources.

run "defaults_no_resources" {
  command = plan

  variables {
    create_permissions      = false
    create_lf_tags          = false
    create_data_filters     = false
    create_governed_tables  = false
    create_iam_role         = false
    role_arn                = "arn:aws:iam::123456789012:role/test"
    data_lake_locations     = {}
    permissions             = {}
    lf_tags                 = {}
    data_cell_filters       = {}
    tags                    = {}
  }

  module {
    source = "../../"
  }
}
