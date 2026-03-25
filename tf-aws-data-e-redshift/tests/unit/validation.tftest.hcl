# unit/validation.tftest.hcl — tf-aws-data-e-redshift
# plan-only: verifies variable validation rules reject invalid inputs.
# Each run block expects an error (expect_failures).

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1 — create_alarms = true without alarm_sns_topic_arn
# ---------------------------------------------------------------------------
run "alarms_require_sns_topic" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
    create_alarms        = true
    alarm_sns_topic_arn  = null
  }

  expect_failures = [
    var.alarm_sns_topic_arn,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — create_iam_role = false requires role_arn to be set
# ---------------------------------------------------------------------------
run "byo_role_arn_required_when_create_false" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
    create_iam_role      = false
    role_arn             = null
  }

  expect_failures = [
    var.role_arn,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — cluster node_type must be a recognised ra3/dc2/ds2 prefix
# ---------------------------------------------------------------------------
run "cluster_node_type_invalid_value" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        node_type           = "t3.large"
        skip_final_snapshot = true
      }
    }
    create_subnet_groups = false
  }

  expect_failures = [
    var.clusters,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — serverless workgroup requires a matching namespace key
# ---------------------------------------------------------------------------
run "serverless_workgroup_requires_namespace" {
  command = plan

  variables {
    create_serverless = true
    serverless_namespaces = {}
    serverless_workgroups = {
      "wg1" = {
        namespace_key      = "missing-namespace"
        subnet_ids         = ["subnet-aabbcc00"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
  }

  expect_failures = [
    var.serverless_workgroups,
  ]
}

# ---------------------------------------------------------------------------
# Test 5 — alarm_cpu_threshold must be between 1 and 100
# ---------------------------------------------------------------------------
run "alarm_cpu_threshold_out_of_range" {
  command = plan

  variables {
    clusters = {
      "warehouse" = {
        skip_final_snapshot = true
      }
    }
    create_subnet_groups  = false
    alarm_cpu_threshold   = 0
  }

  expect_failures = [
    var.alarm_cpu_threshold,
  ]
}
