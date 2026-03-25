provider "aws" { region = var.aws_region }

module "kms" {
  source      = "../../../tf-aws-kms"
  name        = var.kms_name
  name_prefix = var.kms_name_prefix
  environment = var.environment
  project     = var.project
}

module "s3_logs" {
  source      = "../../"
  bucket_name = var.log_bucket_name
  environment = var.environment
  project     = var.project
  owner       = var.log_bucket_owner
  cost_center = var.cost_center
  # No KMS on access log bucket required; AES256 is fine
  sse_algorithm = var.log_sse_algorithm
}

module "s3" {
  source      = "../../"
  bucket_name = var.bucket_name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  force_destroy    = var.force_destroy
  object_ownership = var.object_ownership

  versioning_enabled = var.versioning_enabled
  mfa_delete         = var.mfa_delete

  sse_algorithm      = var.sse_algorithm
  kms_master_key_id  = module.kms.key_arn
  bucket_key_enabled = var.bucket_key_enabled

  # All public access blocked
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  enable_access_logging = var.enable_access_logging
  access_log_bucket     = module.s3_logs.bucket_id
  access_log_prefix     = var.access_log_prefix

  attach_deny_insecure_transport_policy = var.attach_deny_insecure_transport_policy
  attach_require_latest_tls_policy      = var.attach_require_latest_tls_policy

  lifecycle_rules                    = var.lifecycle_rules
  intelligent_tiering_configurations = var.intelligent_tiering_configurations

  tags = var.tags
}
