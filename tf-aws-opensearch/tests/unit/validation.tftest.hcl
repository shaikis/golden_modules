variables {
  name        = "test-opensearch"
  environment = "test"
}

run "timeseries_type_plan" {
  command = plan
  variables {
    collection_type = "TIMESERIES"
  }
  assert {
    condition     = var.collection_type == "TIMESERIES"
    error_message = "TIMESERIES collection type should be accepted."
  }
}
