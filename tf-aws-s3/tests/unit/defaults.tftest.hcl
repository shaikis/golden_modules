# Unit tests — verify default variable values for tf-aws-s3
# command = plan; no real AWS resources are created.

run "s3_defaults" {
  command = plan

  variables {
    bucket_name = "my-test-bucket-defaults-12345"
  }

  # versioning enabled by default
  assert {
    condition     = var.versioning_enabled == true
    error_message = "Expected versioning_enabled to default to true."
  }

  # SSE algorithm defaults to aws:kms
  assert {
    condition     = var.sse_algorithm == "aws:kms"
    error_message = "Expected sse_algorithm to default to 'aws:kms'."
  }

  # No replication configuration by default
  assert {
    condition     = var.replication_configuration == null
    error_message = "Expected replication_configuration to default to null."
  }

  # No notifications by default
  assert {
    condition     = var.notifications == null
    error_message = "Expected notifications to default to null."
  }

  # Public access block enabled by default
  assert {
    condition     = var.block_public_acls == true
    error_message = "Expected block_public_acls to default to true."
  }

  assert {
    condition     = var.block_public_policy == true
    error_message = "Expected block_public_policy to default to true."
  }

  assert {
    condition     = var.ignore_public_acls == true
    error_message = "Expected ignore_public_acls to default to true."
  }

  assert {
    condition     = var.restrict_public_buckets == true
    error_message = "Expected restrict_public_buckets to default to true."
  }

  # object_lock disabled by default
  assert {
    condition     = var.object_lock_enabled == false
    error_message = "Expected object_lock_enabled to default to false."
  }

  # No lifecycle rules by default
  assert {
    condition     = length(var.lifecycle_rules) == 0
    error_message = "Expected lifecycle_rules to default to empty list."
  }

  # No CORS rules by default
  assert {
    condition     = length(var.cors_rules) == 0
    error_message = "Expected cors_rules to default to empty list."
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
