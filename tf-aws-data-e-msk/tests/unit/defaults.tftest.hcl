# unit/defaults.tftest.hcl — tf-aws-data-e-msk
# plan-only: verifies feature-gate defaults and BYO IAM/KMS pattern
# No AWS credentials required; runs entirely as a plan.

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — minimal config: only provisioned MSK cluster is planned
# ---------------------------------------------------------------------------
run "minimal_config_plans_only_cluster" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
  }

  # Core cluster must be planned
  assert {
    condition     = length(aws_msk_cluster.this) == 1
    error_message = "Expected exactly one MSK provisioned cluster to be planned."
  }

  # Serverless gate defaults to false
  assert {
    condition     = length(aws_msk_serverless_cluster.this) == 0
    error_message = "create_serverless_clusters defaults to false; no serverless clusters should be planned."
  }

  # VPC connections gate defaults to false
  assert {
    condition     = length(aws_msk_vpc_connection.this) == 0
    error_message = "create_vpc_connections defaults to false; no VPC connections should be planned."
  }

  # SCRAM auth gate defaults to false
  assert {
    condition     = length(aws_msk_scram_secret_association.this) == 0
    error_message = "create_scram_auth defaults to false; no SCRAM associations should be planned."
  }

  # Alarms gate defaults to false
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "create_alarms defaults to false; no CloudWatch alarms should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 2 — BYO IAM role suppresses auto-create
# ---------------------------------------------------------------------------
run "byo_iam_role_suppresses_creation" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test"
  }

  assert {
    condition     = length(aws_iam_role.producer) == 0
    error_message = "create_iam_role = false should suppress producer IAM role creation."
  }

  assert {
    condition     = length(aws_iam_role.consumer) == 0
    error_message = "create_iam_role = false should suppress consumer IAM role creation."
  }
}

# ---------------------------------------------------------------------------
# Test 3 — BYO KMS key suppresses aws_kms_key creation
# ---------------------------------------------------------------------------
run "byo_kms_key_suppresses_key_creation" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc123"
  }

  assert {
    condition     = length(aws_kms_key.this) == 0
    error_message = "When kms_key_arn is provided, the module must not create a KMS key."
  }
}

# ---------------------------------------------------------------------------
# Test 4 — configurations map defaults to empty
# ---------------------------------------------------------------------------
run "no_configurations_without_opt_in" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
  }

  assert {
    condition     = length(aws_msk_configuration.this) == 0
    error_message = "configurations defaults to empty; no MSK configurations should be planned."
  }
}

# ---------------------------------------------------------------------------
# Test 5 — tag propagation
# ---------------------------------------------------------------------------
run "tags_propagate_to_cluster" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    tags = { Environment = "test", Team = "data-engineering" }
  }

  assert {
    condition     = aws_msk_cluster.this["kafka"].tags["Environment"] == "test"
    error_message = "Environment tag must propagate to the MSK cluster."
  }
}
