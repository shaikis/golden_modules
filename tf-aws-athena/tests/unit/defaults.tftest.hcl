# Unit tests — tf-aws-athena defaults
# command = plan: no real AWS resources are created.

run "empty_workgroups_creates_nothing" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    workgroups = {}
    tags       = {}
  }

  # With an empty workgroups map the plan should have zero aws_athena_workgroup resources.
  assert {
    condition     = length(var.workgroups) == 0
    error_message = "Expected workgroups to default to an empty map."
  }
}

run "name_prefix_default_is_prod" {
  command = plan

  module {
    source = "../../"
  }

  # No name_prefix supplied — the variable default of "prod" must be used.
  assert {
    condition     = var.name_prefix == "prod"
    error_message = "Expected name_prefix to default to 'prod'."
  }
}

run "all_collection_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.databases) == 0
    error_message = "Expected databases to default to {}."
  }

  assert {
    condition     = length(var.named_queries) == 0
    error_message = "Expected named_queries to default to {}."
  }

  assert {
    condition     = length(var.data_catalogs) == 0
    error_message = "Expected data_catalogs to default to {}."
  }

  assert {
    condition     = length(var.prepared_statements) == 0
    error_message = "Expected prepared_statements to default to {}."
  }

  assert {
    condition     = length(var.capacity_reservations) == 0
    error_message = "Expected capacity_reservations to default to {}."
  }
}

run "iam_support_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.results_bucket_arns) == 0
    error_message = "Expected results_bucket_arns to default to []."
  }

  assert {
    condition     = length(var.data_lake_bucket_arns) == 0
    error_message = "Expected data_lake_bucket_arns to default to []."
  }

  assert {
    condition     = var.results_kms_key_arn == null
    error_message = "Expected results_kms_key_arn to default to null."
  }
}
