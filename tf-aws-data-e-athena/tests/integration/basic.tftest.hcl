# Integration test — tf-aws-data-e-athena
# Athena workgroups have no standing cost (pay per query).
# Uses command = apply: workgroups are free to create.

run "athena_workgroup_apply" {
  # SKIP_IN_CI
  # Cost: Athena workgroups have no standing cost (pay per query)
  command = apply

  variables {
    name_prefix = "inttest"

    workgroups = {
      basic = {
        description                        = "Integration test workgroup"
        state                              = "ENABLED"
        enforce_workgroup_configuration    = false
        publish_cloudwatch_metrics_enabled = false
        force_destroy                      = true
      }
    }

    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }
  }

  assert {
    condition     = length(output.workgroup_ids) == 1
    error_message = "Expected exactly one workgroup_id to be created."
  }

  assert {
    condition     = output.workgroup_ids["basic"] != null && output.workgroup_ids["basic"] != ""
    error_message = "workgroup_ids[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.workgroup_arns["basic"] != null && output.workgroup_arns["basic"] != ""
    error_message = "workgroup_arns[\"basic\"] must be a non-empty ARN."
  }

  assert {
    condition     = output.workgroup_names["basic"] != null && output.workgroup_names["basic"] != ""
    error_message = "workgroup_names[\"basic\"] must be a non-empty string."
  }

  assert {
    condition     = output.athena_analyst_role_arn != null && output.athena_analyst_role_arn != ""
    error_message = "athena_analyst_role_arn must be a non-empty ARN."
  }

  assert {
    condition     = output.athena_admin_role_arn != null && output.athena_admin_role_arn != ""
    error_message = "athena_admin_role_arn must be a non-empty ARN."
  }
}
