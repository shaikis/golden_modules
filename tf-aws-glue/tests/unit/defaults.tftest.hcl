# Unit tests — tf-aws-glue defaults
# command = plan: no real AWS resources are created.

run "all_feature_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_catalog_databases == false
    error_message = "Expected create_catalog_databases to default to false."
  }

  assert {
    condition     = var.create_crawlers == false
    error_message = "Expected create_crawlers to default to false."
  }

  assert {
    condition     = var.create_triggers == false
    error_message = "Expected create_triggers to default to false."
  }

  assert {
    condition     = var.create_workflows == false
    error_message = "Expected create_workflows to default to false."
  }

  assert {
    condition     = var.create_connections == false
    error_message = "Expected create_connections to default to false."
  }

  assert {
    condition     = var.create_schema_registries == false
    error_message = "Expected create_schema_registries to default to false."
  }

  assert {
    condition     = var.create_security_configurations == false
    error_message = "Expected create_security_configurations to default to false."
  }

  assert {
    condition     = var.create_catalog_encryption == false
    error_message = "Expected create_catalog_encryption to default to false."
  }
}

run "create_iam_role_defaults_true" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_iam_role == true
    error_message = "Expected create_iam_role to default to true."
  }
}

run "collection_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.catalog_databases) == 0
    error_message = "Expected catalog_databases to default to {}."
  }

  assert {
    condition     = length(var.jobs) == 0
    error_message = "Expected jobs to default to {}."
  }

  assert {
    condition     = length(var.crawlers) == 0
    error_message = "Expected crawlers to default to {}."
  }

  assert {
    condition     = length(var.workflows) == 0
    error_message = "Expected workflows to default to {}."
  }

  assert {
    condition     = length(var.triggers) == 0
    error_message = "Expected triggers to default to {}."
  }
}

run "byo_role_pattern" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    create_iam_role = false
  }

  assert {
    condition     = var.create_iam_role == false
    error_message = "Expected create_iam_role to be false when explicitly disabled."
  }
}
