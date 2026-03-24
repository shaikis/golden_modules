provider "aws" { region = var.aws_region }
data "aws_caller_identity" "current" {}

module "role" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  description = var.description

  trusted_role_services = var.trusted_role_services

  assume_role_conditions = var.assume_role_conditions

  max_session_duration = var.max_session_duration

  managed_policy_arns = var.managed_policy_arns

  inline_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject"]
          Resource = "arn:aws:s3:::${var.s3_data_bucket}/*"
        }
      ]
    })
    kms_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
          Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
        }
      ]
    })
  }

  tags = var.tags
}

output "role_arn" { value = module.role.role_arn }
