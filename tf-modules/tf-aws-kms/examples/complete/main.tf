provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "kms_complete" {
  source = "../../"

  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  description              = var.description
  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  enable_key_rotation      = var.enable_key_rotation
  deletion_window_in_days  = var.deletion_window_in_days
  multi_region             = var.multi_region

  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.kms_admin_role_name}"
  ]

  key_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_server_role_name}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lambda_exec_role_name}",
  ]

  aliases = var.aliases

  grants = {
    autoscaling = {
      grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.autoscaling_role_path}"
      operations        = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "DescribeKey", "CreateGrant"]
    }
  }

  tags = var.tags
}
