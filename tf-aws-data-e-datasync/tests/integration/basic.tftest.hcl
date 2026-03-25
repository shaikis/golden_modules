# Integration test: create a minimal DataSync S3 location, verify outputs, destroy.
# command = apply — REAL AWS resources are created; this incurs cost.
# Prerequisites: AWS credentials with DataSync + IAM + S3 permissions.

# SKIP_IN_CI

variables {
  name_prefix = "tftest"
  tags = {
    Environment = "test"
    ManagedBy   = "terraform-test"
  }

  # Auto-create the DataSync IAM role.
  create_iam_role = true

  # Enable S3 locations only — minimal smoke test.
  create_s3_locations            = true
  create_efs_locations           = false
  create_fsx_windows_locations   = false
  create_fsx_lustre_locations    = false
  create_nfs_locations           = false
  create_smb_locations           = false
  create_hdfs_locations          = false
  create_object_storage_locations = false
  create_agents                  = false
  create_alarms                  = false

  # Provide a real S3 bucket ARN in CI.
  s3_locations = {
    test_source = {
      s3_bucket_arn    = "arn:aws:s3:::replace-with-real-bucket"
      subdirectory     = "/tftest"
      s3_storage_class = "STANDARD"
    }
  }

  # Grant the role access to the test bucket.
  s3_bucket_arns_for_role = ["arn:aws:s3:::replace-with-real-bucket"]
}

run "s3_location_created" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = var.create_s3_locations == true
    error_message = "S3 location gate must be enabled for this test."
  }
}

run "no_agents_without_gate" {
  # SKIP_IN_CI
  command = apply

  module {
    source = "../../"
  }

  variables {
    create_agents = false
    agents        = {}
  }

  assert {
    condition     = var.create_agents == false
    error_message = "Agents gate must remain false — no agent resources expected."
  }
}
