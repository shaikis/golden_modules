variables {
  name          = "test-cr"
  environment   = "test"
  lambda_arn    = "arn:aws:lambda:us-east-1:123456789012:function:test-handler"
  create_lambda = false
}

run "defaults_plan" {
  command = plan

  assert {
    condition     = var.resource_type == "CustomResource"
    error_message = "Default resource_type should be CustomResource."
  }

  assert {
    condition     = var.stack_timeout_minutes == 30
    error_message = "Default timeout should be 30 minutes."
  }
}
