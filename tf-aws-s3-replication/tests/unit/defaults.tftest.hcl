# Unit tests — verify default variable values for tf-aws-s3-replication
# command = plan; no real AWS resources are created.

run "s3_replication_defaults" {
  command = plan

  variables {
    source_bucket_name = "my-test-source-bucket-defaults-12345"
    source_region      = "us-east-1"
  }

  # versioning enabled by default (required for replication)
  assert {
    condition     = var.enable_versioning == true
    error_message = "Expected enable_versioning to default to true."
  }

  # SRR disabled by default
  assert {
    condition     = var.enable_srr == false
    error_message = "Expected enable_srr to default to false."
  }

  # CRR disabled by default
  assert {
    condition     = var.enable_crr == false
    error_message = "Expected enable_crr to default to false."
  }

  # No CRR destinations by default
  assert {
    condition     = length(var.crr_destinations) == 0
    error_message = "Expected crr_destinations to default to empty map."
  }

  # No existing replication role by default
  assert {
    condition     = var.replication_role_arn == null
    error_message = "Expected replication_role_arn to default to null."
  }

  # AWS Backup disabled by default
  assert {
    condition     = var.enable_aws_backup == false
    error_message = "Expected enable_aws_backup to default to false."
  }

  # Object lock disabled by default
  assert {
    condition     = var.object_lock_enabled == false
    error_message = "Expected object_lock_enabled to default to false."
  }

  # MFA delete disabled by default
  assert {
    condition     = var.enable_mfa_delete == false
    error_message = "Expected enable_mfa_delete to default to false."
  }

  # name_prefix defaults to empty string
  assert {
    condition     = var.name_prefix == ""
    error_message = "Expected name_prefix to default to empty string."
  }

  # environment defaults to dev
  assert {
    condition     = var.environment == "dev"
    error_message = "Expected environment to default to 'dev'."
  }
}
