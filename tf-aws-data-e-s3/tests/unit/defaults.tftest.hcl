# Unit test — default variable values for tf-aws-data-e-s3
# command = plan: no real AWS resources are created.

run "defaults_feature_gates" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    bucket_name = "test-s3-defaults-123456"
  }

  assert {
    condition     = var.versioning_enabled == true
    error_message = "versioning_enabled must default to true."
  }

  assert {
    condition     = var.lifecycle_rules == []
    error_message = "lifecycle_rules must default to an empty list (create_lifecycle_rules pattern = false)."
  }

  assert {
    condition     = var.replication_configuration == null
    error_message = "replication_configuration must default to null (create_replication pattern = false)."
  }

  assert {
    condition     = var.kms_master_key_id == null
    error_message = "kms_master_key_id must default to null (BYO KMS pattern)."
  }

  assert {
    condition     = var.sse_algorithm == "aws:kms"
    error_message = "sse_algorithm must default to aws:kms."
  }

  assert {
    condition     = var.block_public_acls == true
    error_message = "block_public_acls must default to true."
  }

  assert {
    condition     = var.block_public_policy == true
    error_message = "block_public_policy must default to true."
  }
}

run "byo_kms_key_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    bucket_name      = "test-s3-byo-kms-123456"
    kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  }

  assert {
    condition     = var.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "kms_master_key_id should be accepted as a BYO key."
  }
}
