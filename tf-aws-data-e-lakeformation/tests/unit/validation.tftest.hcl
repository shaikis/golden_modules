# tests/unit/validation.tftest.hcl
# Verifies that an invalid Lake Formation permission type is rejected
# by module input validation.

run "invalid_permission_type_rejected" {
  command = plan

  variables {
    create_permissions = true
    create_iam_role    = false
    role_arn           = "arn:aws:iam::123456789012:role/test"

    permissions = {
      bad_perm = {
        principal   = "arn:aws:iam::123456789012:role/test"
        # INVALID permission value — must be rejected by validation.
        permissions = ["INVALID_PERMISSION_TYPE"]

        database = {
          name = "test_database"
        }
      }
    }
  }

  module {
    source = "../../"
  }

  # Expect the plan to fail because the permission value is not a valid
  # Lake Formation permission type.
  expect_failures = [
    var.permissions,
  ]
}
