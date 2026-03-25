# Unit tests — tf-aws-ses defaults
# command = plan: no real AWS resources are created.

run "all_feature_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_configuration_sets == false
    error_message = "Expected create_configuration_sets to default to false."
  }

  assert {
    condition     = var.create_receipt_rules == false
    error_message = "Expected create_receipt_rules to default to false."
  }

  assert {
    condition     = var.create_templates == false
    error_message = "Expected create_templates to default to false."
  }

  assert {
    condition     = var.create_iam_roles == false
    error_message = "Expected create_iam_roles to default to false."
  }
}

run "identity_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.domain_identities) == 0
    error_message = "Expected domain_identities to default to {}."
  }

  assert {
    condition     = length(var.email_identities) == 0
    error_message = "Expected email_identities to default to {}."
  }
}

run "collection_vars_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.configuration_sets) == 0
    error_message = "Expected configuration_sets to default to {}."
  }

  assert {
    condition     = length(var.rule_sets) == 0
    error_message = "Expected rule_sets to default to {}."
  }

  assert {
    condition     = length(var.receipt_rules) == 0
    error_message = "Expected receipt_rules to default to {}."
  }

  assert {
    condition     = length(var.templates) == 0
    error_message = "Expected templates to default to {}."
  }
}

run "iam_role_gates_default_false" {
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_firehose_role == false
    error_message = "Expected create_firehose_role to default to false."
  }

  assert {
    condition     = var.create_s3_role == false
    error_message = "Expected create_s3_role to default to false."
  }
}
