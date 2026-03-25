# Unit tests — tf-aws-dynamodb variable validation
# command = plan (no AWS resources created)

# ---------------------------------------------------------------------------
# Test: PAY_PER_REQUEST billing mode accepted
# ---------------------------------------------------------------------------
run "billing_mode_pay_per_request" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      events = {
        hash_key     = "event_id"
        billing_mode = "PAY_PER_REQUEST"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["events"].billing_mode == "PAY_PER_REQUEST"
    error_message = "PAY_PER_REQUEST billing mode should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: PROVISIONED billing mode with capacity
# ---------------------------------------------------------------------------
run "billing_mode_provisioned" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      throughput = {
        hash_key       = "pk"
        billing_mode   = "PROVISIONED"
        read_capacity  = 10
        write_capacity = 10
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["throughput"].billing_mode == "PROVISIONED"
    error_message = "PROVISIONED billing mode should be accepted."
  }

  assert {
    condition     = var.tables["throughput"].read_capacity == 10
    error_message = "read_capacity should be 10."
  }
}

# ---------------------------------------------------------------------------
# Test: Hash key type defaults to S (string)
# ---------------------------------------------------------------------------
run "hash_key_type_default_string" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      items = {
        hash_key = "item_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["items"].hash_key_type == "S"
    error_message = "Default hash_key_type should be S (string)."
  }
}

# ---------------------------------------------------------------------------
# Test: Numeric hash key type accepted
# ---------------------------------------------------------------------------
run "hash_key_type_number" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      metrics = {
        hash_key      = "timestamp"
        hash_key_type = "N"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["metrics"].hash_key_type == "N"
    error_message = "Numeric hash_key_type N should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: Stream view type defaults to NEW_AND_OLD_IMAGES
# ---------------------------------------------------------------------------
run "stream_view_type_default" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      audit = {
        hash_key       = "audit_id"
        stream_enabled = true
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["audit"].stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "Default stream_view_type should be NEW_AND_OLD_IMAGES."
  }
}

# ---------------------------------------------------------------------------
# Test: Table class STANDARD_INFREQUENT_ACCESS accepted
# ---------------------------------------------------------------------------
run "table_class_infrequent_access" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      archive = {
        hash_key    = "archive_id"
        table_class = "STANDARD_INFREQUENT_ACCESS"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.tables["archive"].table_class == "STANDARD_INFREQUENT_ACCESS"
    error_message = "STANDARD_INFREQUENT_ACCESS table class should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Test: GSI configuration is accepted
# ---------------------------------------------------------------------------
run "table_with_gsi" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      orders = {
        hash_key  = "order_id"
        range_key = "created_at"
        global_secondary_indexes = [
          {
            name            = "customer-index"
            hash_key        = "customer_id"
            projection_type = "ALL"
          }
        ]
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = length(var.tables["orders"].global_secondary_indexes) == 1
    error_message = "One GSI should be present."
  }

  assert {
    condition     = var.tables["orders"].global_secondary_indexes[0].name == "customer-index"
    error_message = "GSI name should be customer-index."
  }
}

# ---------------------------------------------------------------------------
# Test: Latency threshold defaults
# ---------------------------------------------------------------------------
run "latency_threshold_defaults" {
  command = plan

  variables {
    name_prefix = "test"
    tables = {
      requests = {
        hash_key = "request_id"
      }
    }
  }

  module {
    source = "../../"
  }

  assert {
    condition     = var.latency_threshold_ms == 100
    error_message = "Default latency threshold should be 100ms."
  }

  assert {
    condition     = var.replication_latency_threshold_ms == 500
    error_message = "Default replication latency threshold should be 500ms."
  }
}
