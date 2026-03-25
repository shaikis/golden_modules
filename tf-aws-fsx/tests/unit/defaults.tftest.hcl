# Unit tests — verify default variable values for tf-aws-fsx
# command = plan; no real AWS resources are created.

run "fsx_defaults_all_types_null" {
  command = plan

  variables {
    name = "test-fsx"
  }

  # All filesystem type variables default to null (nothing created)
  assert {
    condition     = var.windows == null
    error_message = "Expected windows to default to null."
  }

  assert {
    condition     = var.lustre == null
    error_message = "Expected lustre to default to null."
  }

  assert {
    condition     = var.ontap == null
    error_message = "Expected ontap to default to null."
  }

  assert {
    condition     = var.openzfs == null
    error_message = "Expected openzfs to default to null."
  }

  # KMS key defaults to null (AWS-managed encryption)
  assert {
    condition     = var.kms_key_arn == null
    error_message = "Expected kms_key_arn to default to null."
  }

  # ONTAP backup disabled by default
  assert {
    condition     = var.enable_ontap_backup == false
    error_message = "Expected enable_ontap_backup to default to false."
  }

  # Cross-region backup disabled by default
  assert {
    condition     = var.enable_ontap_cross_region_backup == false
    error_message = "Expected enable_ontap_cross_region_backup to default to false."
  }

  # environment defaults to dev
  assert {
    condition     = var.environment == "dev"
    error_message = "Expected environment to default to 'dev'."
  }
}
