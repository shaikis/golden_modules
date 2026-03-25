# Unit tests — defaults and feature gates for tf-aws-lambda
# command = plan  →  no AWS resources are created; free to run on every PR.

variables {
  function_name = "test-lambda"
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

module {
  source = "../../"
}

# ---------------------------------------------------------------------------
# create_function_url defaults to false
# ---------------------------------------------------------------------------
run "create_function_url_default_false" {
  command = plan

  assert {
    condition     = var.create_function_url == false
    error_message = "create_function_url must default to false."
  }
}

# ---------------------------------------------------------------------------
# event_source_mappings empty by default
# ---------------------------------------------------------------------------
run "event_source_mappings_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.event_source_mappings) == 0
    error_message = "event_source_mappings must be empty by default."
  }
}

# ---------------------------------------------------------------------------
# create_cloudwatch_alarms defaults to false
# ---------------------------------------------------------------------------
run "create_cloudwatch_alarms_default_false" {
  command = plan

  assert {
    condition     = var.create_cloudwatch_alarms == false
    error_message = "create_cloudwatch_alarms must default to false."
  }
}

# ---------------------------------------------------------------------------
# create_role defaults to true (auto-create IAM role)
# ---------------------------------------------------------------------------
run "create_role_default_true" {
  command = plan

  assert {
    condition     = var.create_role == true
    error_message = "create_role must default to true."
  }
}

# ---------------------------------------------------------------------------
# BYO role: when role_arn is provided, create_role can be set to false
# ---------------------------------------------------------------------------
run "byo_role_pattern" {
  command = plan

  variables {
    function_name = "test-lambda-byo"
    create_role   = false
    role_arn      = "arn:aws:iam::123456789012:role/test-role"
  }

  assert {
    condition     = var.create_role == false
    error_message = "create_role must accept false for BYO role pattern."
  }

  assert {
    condition     = var.role_arn == "arn:aws:iam::123456789012:role/test-role"
    error_message = "BYO role_arn must be passed through unchanged."
  }
}

# ---------------------------------------------------------------------------
# runtime defaults to python3.12
# ---------------------------------------------------------------------------
run "runtime_default" {
  command = plan

  assert {
    condition     = var.runtime == "python3.12"
    error_message = "Default runtime must be python3.12."
  }
}

# ---------------------------------------------------------------------------
# package_type defaults to Zip
# ---------------------------------------------------------------------------
run "package_type_default_zip" {
  command = plan

  assert {
    condition     = var.package_type == "Zip"
    error_message = "package_type must default to Zip."
  }
}

# ---------------------------------------------------------------------------
# publish defaults to true (required for aliases and provisioned concurrency)
# ---------------------------------------------------------------------------
run "publish_default_true" {
  command = plan

  assert {
    condition     = var.publish == true
    error_message = "publish must default to true."
  }
}

# ---------------------------------------------------------------------------
# VPC-less by default (subnet_ids empty)
# ---------------------------------------------------------------------------
run "no_vpc_by_default" {
  command = plan

  assert {
    condition     = length(var.subnet_ids) == 0
    error_message = "subnet_ids must default to empty — Lambda is not VPC-attached by default."
  }
}

# ---------------------------------------------------------------------------
# Function URL gate: enabled when create_function_url = true
# ---------------------------------------------------------------------------
run "function_url_gate_enabled" {
  command = plan

  variables {
    function_name       = "test-lambda-url"
    create_function_url = true
  }

  assert {
    condition     = var.create_function_url == true
    error_message = "create_function_url gate must accept true."
  }
}

# ---------------------------------------------------------------------------
# create_cloudwatch_dashboard defaults to false
# ---------------------------------------------------------------------------
run "cloudwatch_dashboard_default_false" {
  command = plan

  assert {
    condition     = var.create_cloudwatch_dashboard == false
    error_message = "create_cloudwatch_dashboard must default to false."
  }
}
