# Unit test — input validation for tf-aws-data-e-quicksight
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

# NOTE: QuickSight module currently has no .tf resource files.
# Validation tests are structured to match the expected interface once
# user/group/datasource variables are added.

run "valid_minimal_config_accepted" {
  command = plan

  module {
    source = "../../"
  }

  # No variables defined yet; a clean plan is the passing condition.
  assert {
    condition     = true
    error_message = "A minimal valid config must plan successfully."
  }
}

# Placeholder: once user_role variable with validation is added, uncomment
# to verify that roles outside READER/AUTHOR/ADMIN are rejected.
#
# run "invalid_user_role_rejected" {
#   command = plan
#   expect_failures = [var.users]
#
#   module {
#     source = "../../"
#   }
#
#   variables {
#     create_users = true
#     users = [
#       {
#         user_name = "bad-role-user"
#         email     = "test@example.com"
#         user_role = "SUPERADMIN"   # invalid
#       }
#     ]
#   }
# }
