# unit/validation.tftest.hcl — tf-aws-data-e-msk
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
# Test 1 — cluster client_subnets must not be empty
# ---------------------------------------------------------------------------
run "cluster_requires_client_subnets" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = []
        security_group_ids = ["sg-aabbcc00"]
      }
    }
  }

  expect_failures = [
    var.clusters,
  ]
}

# ---------------------------------------------------------------------------
# Test 2 — cluster security_group_ids must not be empty
# ---------------------------------------------------------------------------
run "cluster_requires_security_groups" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = []
      }
    }
  }

  expect_failures = [
    var.clusters,
  ]
}

# ---------------------------------------------------------------------------
# Test 3 — encryption_in_transit must be TLS, TLS_PLAINTEXT, or PLAINTEXT
# ---------------------------------------------------------------------------
run "encryption_in_transit_invalid_value" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets        = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids    = ["sg-aabbcc00"]
        encryption_in_transit = "NONE"
      }
    }
  }

  expect_failures = [
    var.clusters,
  ]
}

# ---------------------------------------------------------------------------
# Test 4 — create_alarms = true without alarm_sns_topic_arn
# ---------------------------------------------------------------------------
run "alarms_require_sns_topic" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    create_alarms       = true
    alarm_sns_topic_arn = null
  }

  expect_failures = [
    var.alarm_sns_topic_arn,
  ]
}

# ---------------------------------------------------------------------------
# Test 5 — create_iam_role = false requires role_arn to be set
# ---------------------------------------------------------------------------
run "byo_role_arn_required_when_create_false" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    create_iam_role = false
    role_arn        = null
  }

  expect_failures = [
    var.role_arn,
  ]
}

# ---------------------------------------------------------------------------
# Test 6 — alarm thresholds must be positive percentages (0–100)
# ---------------------------------------------------------------------------
run "alarm_disk_threshold_out_of_range" {
  command = plan

  variables {
    clusters = {
      "kafka" = {
        client_subnets     = ["subnet-aabbcc00", "subnet-ddeeff11", "subnet-aabb2233"]
        security_group_ids = ["sg-aabbcc00"]
      }
    }
    alarm_disk_used_percent_threshold = 110
  }

  expect_failures = [
    var.alarm_disk_used_percent_threshold,
  ]
}
