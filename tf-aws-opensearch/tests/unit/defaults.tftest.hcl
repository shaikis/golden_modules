variables {
  name        = "test-opensearch"
  environment = "test"
}

run "serverless_defaults_plan" {
  command = plan

  assert {
    condition     = var.create_serverless == true
    error_message = "Serverless should be enabled by default."
  }

  assert {
    condition     = var.collection_type == "VECTORSEARCH"
    error_message = "Default collection type should be VECTORSEARCH."
  }

  assert {
    condition     = var.standby_replicas == "ENABLED"
    error_message = "Standby replicas should be ENABLED by default."
  }

  assert {
    condition     = var.network_access_type == "PUBLIC"
    error_message = "Default network access type should be PUBLIC."
  }
}

run "vector_collection_plan" {
  command = plan

  variables {
    collection_type  = "VECTORSEARCH"
    standby_replicas = "DISABLED"
  }

  assert {
    condition     = var.collection_type == "VECTORSEARCH"
    error_message = "Collection type should be VECTORSEARCH."
  }
}
