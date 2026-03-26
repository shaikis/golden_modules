# Unit test — validates defaults without creating real resources

variables {
  name        = "test-amp"
  environment = "test"
}

run "defaults_plan" {
  command = plan

  assert {
    condition     = aws_prometheus_workspace.this.alias == "test-amp"
    error_message = "Workspace alias should default to name."
  }

  assert {
    condition     = var.enable_alert_manager == false
    error_message = "Alert manager should be disabled by default."
  }

  assert {
    condition     = var.create_irsa_role == false
    error_message = "IRSA role should be disabled by default."
  }

  assert {
    condition     = var.create_managed_scraper == false
    error_message = "Managed scraper should be disabled by default."
  }
}
