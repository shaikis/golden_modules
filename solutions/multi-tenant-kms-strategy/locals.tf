locals {
  name = "${var.name_prefix}-${var.environment}-${var.project}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Solution    = "multi-tenant-kms-strategy"
  })

  tenant_keys = {
    for tenant_id in var.tenant_ids : replace(tenant_id, "-", "_") => {
      description         = "Tenant CMK for ${tenant_id}"
      enable_key_rotation = true
      user_principals     = [module.service_a_role.role_arn]
      additional_aliases  = ["alias/customer-${tenant_id}"]
      tags = {
        TenantId = tenant_id
      }
    }
  }

  tenant_aliases = {
    for tenant_id in var.tenant_ids : tenant_id => "alias/customer-${tenant_id}"
  }

  service_a_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKmsByTenantAlias"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:RequestAlias" = "alias/customer-*"
          }
        }
      }
    ]
  })

  service_b_inline_policies = {
    assume_central_kms_role = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["sts:AssumeRole"]
          Resource = module.service_a_role.role_arn
        }
      ]
    })
    write_encrypted_data = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:UpdateItem"
          ]
          Resource = module.tenant_data.table_arns["tenant_data"]
        }
      ]
    })
    cloudwatch_logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
