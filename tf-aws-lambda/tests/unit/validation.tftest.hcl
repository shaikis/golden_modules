# Unit tests — variable validation rules for tf-aws-lambda
# command = plan  →  no AWS resources are created; free to run on every PR.

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
# package_type: "Zip" accepted
# ---------------------------------------------------------------------------
run "package_type_zip_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-zip"
    package_type  = "Zip"
  }

  assert {
    condition     = var.package_type == "Zip"
    error_message = "package_type 'Zip' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# package_type: "Image" accepted
# ---------------------------------------------------------------------------
run "package_type_image_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-image"
    package_type  = "Image"
  }

  assert {
    condition     = var.package_type == "Image"
    error_message = "package_type 'Image' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# architectures: ["x86_64"] accepted
# ---------------------------------------------------------------------------
run "architecture_x86_64_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-x86"
    architectures = ["x86_64"]
  }

  assert {
    condition     = contains(var.architectures, "x86_64")
    error_message = "x86_64 architecture must be accepted."
  }
}

# ---------------------------------------------------------------------------
# architectures: ["arm64"] accepted
# ---------------------------------------------------------------------------
run "architecture_arm64_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-arm"
    architectures = ["arm64"]
  }

  assert {
    condition     = contains(var.architectures, "arm64")
    error_message = "arm64 (Graviton) architecture must be accepted."
  }
}

# ---------------------------------------------------------------------------
# tracing_mode: "PassThrough" default accepted
# ---------------------------------------------------------------------------
run "tracing_passthrough_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-tracing"
    tracing_mode  = "PassThrough"
  }

  assert {
    condition     = var.tracing_mode == "PassThrough"
    error_message = "tracing_mode 'PassThrough' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# tracing_mode: "Active" accepted
# ---------------------------------------------------------------------------
run "tracing_active_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-xray"
    tracing_mode  = "Active"
  }

  assert {
    condition     = var.tracing_mode == "Active"
    error_message = "tracing_mode 'Active' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# snap_start: "None" accepted
# ---------------------------------------------------------------------------
run "snap_start_none_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-snap"
    snap_start    = "None"
  }

  assert {
    condition     = var.snap_start == "None"
    error_message = "snap_start 'None' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# snap_start: "PublishedVersions" accepted
# ---------------------------------------------------------------------------
run "snap_start_published_versions_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-snap2"
    snap_start    = "PublishedVersions"
  }

  assert {
    condition     = var.snap_start == "PublishedVersions"
    error_message = "snap_start 'PublishedVersions' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# function_url_auth_type: "AWS_IAM" default accepted
# ---------------------------------------------------------------------------
run "function_url_auth_iam_accepted" {
  command = plan

  variables {
    function_name          = "test-lambda-url"
    create_function_url    = true
    function_url_auth_type = "AWS_IAM"
  }

  assert {
    condition     = var.function_url_auth_type == "AWS_IAM"
    error_message = "function_url_auth_type 'AWS_IAM' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# function_url_auth_type: "NONE" accepted (public endpoint)
# ---------------------------------------------------------------------------
run "function_url_auth_none_accepted" {
  command = plan

  variables {
    function_name          = "test-lambda-public"
    create_function_url    = true
    function_url_auth_type = "NONE"
  }

  assert {
    condition     = var.function_url_auth_type == "NONE"
    error_message = "function_url_auth_type 'NONE' must be accepted for public endpoints."
  }
}

# ---------------------------------------------------------------------------
# log_format: "Text" default accepted
# ---------------------------------------------------------------------------
run "log_format_text_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-log"
    log_format    = "Text"
  }

  assert {
    condition     = var.log_format == "Text"
    error_message = "log_format 'Text' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# log_format: "JSON" accepted
# ---------------------------------------------------------------------------
run "log_format_json_accepted" {
  command = plan

  variables {
    function_name = "test-lambda-json-log"
    log_format    = "JSON"
  }

  assert {
    condition     = var.log_format == "JSON"
    error_message = "log_format 'JSON' must be accepted."
  }
}

# ---------------------------------------------------------------------------
# log_retention_days: valid value 30 (default) accepted
# ---------------------------------------------------------------------------
run "log_retention_30_days_accepted" {
  command = plan

  variables {
    function_name      = "test-lambda-retention"
    log_retention_days = 30
  }

  assert {
    condition     = var.log_retention_days == 30
    error_message = "log_retention_days 30 must be accepted."
  }
}
