variables {
  name        = "test-amp"
  environment = "test"
}

run "custom_alias" {
  command = plan

  variables {
    workspace_alias = "my-custom-alias"
  }

  assert {
    condition     = aws_prometheus_workspace.this.alias == "my-custom-alias"
    error_message = "Custom workspace alias should be used when provided."
  }
}
