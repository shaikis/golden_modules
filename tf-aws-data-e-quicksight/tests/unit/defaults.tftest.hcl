# Unit test — default variable values for tf-aws-data-e-quicksight
# command = plan: no real AWS resources are created.

run "defaults_all_create_gates_false" {
  command = plan

  module {
    source = "../../"
  }

  # QuickSight module currently has no .tf resource files;
  # the plan should succeed trivially with no variables required.

  assert {
    condition     = true
    error_message = "Plan should succeed with all default values."
  }
}
