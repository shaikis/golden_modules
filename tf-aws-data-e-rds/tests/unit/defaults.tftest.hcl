# Unit test — default variable values for tf-aws-data-e-rds
# command = plan: no real AWS resources are created.

run "defaults_create_clusters_false" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                 = "test-rds-defaults"
    db_subnet_group_name = "default"
  }

  assert {
    condition     = var.engine == "postgres"
    error_message = "engine must default to postgres."
  }

  assert {
    condition     = var.instance_class == "db.t3.medium"
    error_message = "instance_class must default to db.t3.medium."
  }

  assert {
    condition     = var.kms_key_id == null
    error_message = "kms_key_id must default to null (BYO encryption pattern)."
  }

  assert {
    condition     = var.multi_az == true
    error_message = "multi_az must default to true."
  }

  assert {
    condition     = var.deletion_protection == true
    error_message = "deletion_protection must default to true."
  }

  assert {
    condition     = var.storage_encrypted == true
    error_message = "storage_encrypted must default to true."
  }

  assert {
    condition     = var.manage_master_user_password == true
    error_message = "manage_master_user_password must default to true."
  }
}

run "byo_kms_key_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    name                 = "test-rds-byo-kms"
    db_subnet_group_name = "default"
    kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  }

  assert {
    condition     = var.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "kms_key_id should be accepted as a BYO KMS key."
  }
}
