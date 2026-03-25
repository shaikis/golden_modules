# Unit test — default variable values for tf-aws-data-e-lambda
# command = plan: no real AWS resources are created.

run "defaults_optional_gates_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-defaults"
    # Provide minimal inline zip so plan does not error on missing package.
    filename = null
  }

  assert {
    condition     = var.create_function_url == false
    error_message = "create_function_url must default to false."
  }

  assert {
    condition     = var.create_cloudwatch_alarms == false
    error_message = "create_cloudwatch_alarms must default to false."
  }

  assert {
    condition     = var.event_source_mappings == {}
    error_message = "event_source_mappings must default to an empty map."
  }

  assert {
    condition     = var.lambda_layers == {}
    error_message = "lambda_layers must default to an empty map (create_layers pattern = false)."
  }

  assert {
    condition     = var.role_arn == null
    error_message = "role_arn must default to null (BYO role pattern)."
  }

  assert {
    condition     = var.kms_key_arn == null
    error_message = "kms_key_arn must default to null (BYO encryption pattern)."
  }

  assert {
    condition     = var.runtime == "python3.12"
    error_message = "runtime must default to python3.12."
  }
}

run "byo_role_arn_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-byo-role"
    create_role   = false
    role_arn      = "arn:aws:iam::123456789012:role/test"
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/test"
    error_message = "Provided role_arn should be accepted unchanged."
  }

  assert {
    condition     = var.create_role == false
    error_message = "create_role should be false when BYO role is supplied."
  }
}
