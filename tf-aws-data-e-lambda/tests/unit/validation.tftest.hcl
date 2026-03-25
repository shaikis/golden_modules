# Unit test — input validation for tf-aws-data-e-lambda
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

run "valid_runtime_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-valid-runtime"
    runtime       = "python3.12"
  }

  assert {
    condition     = var.runtime == "python3.12"
    error_message = "python3.12 is a valid runtime and should be accepted."
  }
}

run "valid_package_type_zip_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-zip"
    package_type  = "Zip"
    runtime       = "python3.12"
    handler       = "index.handler"
  }

  assert {
    condition     = var.package_type == "Zip"
    error_message = "package_type Zip must be accepted."
  }
}

run "invalid_package_type_rejected" {
  command = plan
  expect_failures = [var.package_type]

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-bad-pkg"
    package_type  = "Tarball"
  }
}

run "invalid_architecture_rejected" {
  command = plan
  expect_failures = [var.architectures]

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-bad-arch"
    architectures = ["sparc64"]
  }
}

run "invalid_snap_start_rejected" {
  command = plan
  expect_failures = [var.snap_start]

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-bad-snap"
    snap_start    = "Enabled"
  }
}

run "invalid_tracing_mode_rejected" {
  command = plan
  expect_failures = [var.tracing_mode]

  module {
    source = "../../"
  }

  variables {
    function_name = "test-lambda-bad-trace"
    tracing_mode  = "ALWAYS"
  }
}

run "invalid_function_url_auth_type_rejected" {
  command = plan
  expect_failures = [var.function_url_auth_type]

  module {
    source = "../../"
  }

  variables {
    function_name           = "test-lambda-bad-auth"
    create_function_url     = true
    function_url_auth_type  = "BEARER"
  }
}
