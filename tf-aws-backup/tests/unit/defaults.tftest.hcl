# Unit tests — tf-aws-backup defaults
# command = plan: no real AWS resources are created.

run "feature_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-backup"
  }

  assert {
    condition     = var.create_framework == false
    error_message = "Expected create_framework to default to false."
  }

  assert {
    condition     = var.configure_global_settings == false
    error_message = "Expected configure_global_settings to default to false."
  }

  assert {
    condition     = var.configure_region_settings == false
    error_message = "Expected configure_region_settings to default to false."
  }

  assert {
    condition     = var.create_sns_topic == false
    error_message = "Expected create_sns_topic to default to false."
  }

  assert {
    condition     = var.enable_cloudwatch_logs == false
    error_message = "Expected enable_cloudwatch_logs to default to false."
  }

  assert {
    condition     = var.create_cloudwatch_alarms == false
    error_message = "Expected create_cloudwatch_alarms to default to false."
  }

  assert {
    condition     = var.create_cloudwatch_dashboard == false
    error_message = "Expected create_cloudwatch_dashboard to default to false."
  }
}

run "iam_role_created_by_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-backup"
  }

  assert {
    condition     = var.create_iam_role == true
    error_message = "Expected create_iam_role to default to true."
  }
}

run "minimal_vault_creation" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-backup"
    vaults = {
      primary = {}
    }
  }

  assert {
    condition     = length(var.vaults) == 1
    error_message = "Expected exactly one vault in the plan."
  }
}

run "collection_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-backup"
  }

  assert {
    condition     = length(var.vaults) == 0
    error_message = "Expected vaults to default to {}."
  }

  assert {
    condition     = length(var.plans) == 0
    error_message = "Expected plans to default to {}."
  }

  assert {
    condition     = length(var.selections) == 0
    error_message = "Expected selections to default to {}."
  }

  assert {
    condition     = length(var.report_plans) == 0
    error_message = "Expected report_plans to default to {}."
  }
}

run "byo_iam_role_pattern" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name            = "test-backup"
    create_iam_role = false
    iam_role_arn    = "arn:aws:iam::123456789012:role/test-role"
  }

  assert {
    condition     = var.create_iam_role == false
    error_message = "Expected create_iam_role to be false when BYO role ARN is supplied."
  }

  assert {
    condition     = var.iam_role_arn == "arn:aws:iam::123456789012:role/test-role"
    error_message = "Expected iam_role_arn to equal the supplied ARN."
  }
}
