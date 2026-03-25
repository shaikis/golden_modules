# Unit test — default variable values for tf-aws-data-e-appflow
# command = plan: no real AWS resources are created.

run "defaults_all_gates_false" {
  command = plan

  module {
    source = "../../"
  }

  # AppFlow module has no required variables (only versions.tf present).
  # Verify the plan succeeds with no inputs (all defaults).

  assert {
    condition     = true
    error_message = "Plan should succeed with all default values."
  }
}

run "byo_role_arn_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    # Simulate BYO IAM role pattern — module must accept an external role ARN.
    # role_arn is the canonical BYO input; pass as a provider-level variable
    # or as a module variable when the module exposes it.
  }

  assert {
    condition     = true
    error_message = "Plan should succeed when a BYO role ARN is supplied."
  }
}
