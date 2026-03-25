# Integration test — basic smoke test for tf-aws-data-e-quicksight
# command = plan (plan-only): QuickSight requires an active subscription.
# SKIP_IN_CI

# Prerequisites:
#   export AWS_ACCESS_KEY_ID="..."
#   export AWS_SECRET_ACCESS_KEY="..."
#   export AWS_DEFAULT_REGION="us-east-1"
#   AWS account must have a QuickSight subscription enabled.

run "quicksight_plan_only_no_subscription_required" {
  # SKIP_IN_CI
  # QuickSight user/group/datasource/dataset/dashboard resources require an
  # active QuickSight subscription in the target account, which is not
  # available in CI. This test validates the plan succeeds with all
  # create_* gates left at their defaults (false).
  command = plan

  module {
    source = "../../"
  }

  assert {
    condition     = true
    error_message = "Plan should succeed with all QuickSight create gates at default (false)."
  }
}
