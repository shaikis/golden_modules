# Unit tests — tf-aws-bedrock defaults
# command = plan: no real AWS resources are created.

run "all_feature_flags_default_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
  }

  assert {
    condition     = var.enable_model_invocation_logging == false
    error_message = "Expected enable_model_invocation_logging to default to false."
  }
}

run "optional_collections_default_empty" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
  }

  assert {
    condition     = length(var.guardrails) == 0
    error_message = "Expected guardrails to default to {}."
  }

  assert {
    condition     = length(var.knowledge_bases) == 0
    error_message = "Expected knowledge_bases to default to {}."
  }

  assert {
    condition     = length(var.agents) == 0
    error_message = "Expected agents to default to {}."
  }
}

run "logging_s3_bucket_defaults_null" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
  }

  assert {
    condition     = var.invocation_log_s3_bucket == null
    error_message = "Expected invocation_log_s3_bucket to default to null."
  }

  assert {
    condition     = var.invocation_log_cloudwatch_log_group == null
    error_message = "Expected invocation_log_cloudwatch_log_group to default to null."
  }

  assert {
    condition     = var.kms_key_arn == null
    error_message = "Expected kms_key_arn to default to null."
  }
}

run "log_prefix_has_sensible_default" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
  }

  assert {
    condition     = var.invocation_log_s3_prefix == "bedrock-logs/"
    error_message = "Expected invocation_log_s3_prefix to default to 'bedrock-logs/'."
  }
}

run "byo_name_prefix_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "test-bedrock"
    name_prefix = "myteam-"
    environment = "staging"
  }

  assert {
    condition     = var.name_prefix == "myteam-"
    error_message = "Expected name_prefix to reflect the supplied value."
  }
}
