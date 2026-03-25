# Unit test — default variable values for tf-aws-data-e-bedrock
# command = plan: no real AWS resources are created.

run "defaults_all_create_gates_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name = "test-bedrock"
  }

  # With no guardrails/knowledge_bases/agents maps supplied the module
  # should plan with zero resources to create.

  assert {
    condition     = var.guardrails == {}
    error_message = "guardrails must default to an empty map (create_guardrails pattern = false)."
  }

  assert {
    condition     = var.knowledge_bases == {}
    error_message = "knowledge_bases must default to an empty map (create_knowledge_bases pattern = false)."
  }

  assert {
    condition     = var.agents == {}
    error_message = "agents must default to an empty map (create_agents pattern = false)."
  }

  assert {
    condition     = var.kms_key_arn == null
    error_message = "kms_key_arn must default to null (BYO encryption pattern)."
  }

  assert {
    condition     = var.enable_model_invocation_logging == false
    error_message = "enable_model_invocation_logging must default to false."
  }
}

run "byo_kms_key_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name        = "test-bedrock-kms"
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  }

  assert {
    condition     = var.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "kms_key_arn should be accepted as a BYO key."
  }
}
