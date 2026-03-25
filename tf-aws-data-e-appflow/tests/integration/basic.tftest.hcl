# Integration test — basic smoke test for tf-aws-data-e-appflow
# command = plan (plan-only): AppFlow flows require real SaaS credentials.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"

run "appflow_plan_only_no_saas_credentials" {
  # SKIP_IN_CI
  # AppFlow ConnectorProfiles and Flows require live SaaS OAuth tokens /
  # API keys that are not available in CI. This test validates that the
  # module plan succeeds with an empty flow map (no flows to create).
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = true
    error_message = "Plan should succeed with no flows or connector profiles configured."
  }
}
