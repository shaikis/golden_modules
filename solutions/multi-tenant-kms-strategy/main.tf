data "archive_file" "tenant_encryptor" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/tenant_encryptor.py"
  output_path = "${path.module}/tenant_encryptor.zip"
}

module "tenant_data" {
  source = "../../tf-aws-dynamodb"

  providers = {
    aws = aws.workload
  }

  name_prefix = "${var.name_prefix}-${var.environment}"
  tags        = local.common_tags

  tables = {
    tenant_data = {
      billing_mode              = "PAY_PER_REQUEST"
      hash_key                  = "pk"
      hash_key_type             = "S"
      range_key                 = "sk"
      range_key_type            = "S"
      point_in_time_recovery    = true
      deletion_protection       = true
      kms_key_arn               = var.dynamodb_kms_key_arn
      contributor_insights      = true
      backup_enabled            = true
      global_secondary_indexes  = []
      local_secondary_indexes   = []
      tags = {
        DataPattern = "client-side-encrypted"
      }
    }
  }

  create_alarms      = false
  create_backup_plan = false
  create_iam_roles   = false
}

module "service_b_role" {
  source = "../../tf-aws-iam-role"

  providers = {
    aws = aws.workload
  }

  name                  = "service-b-role"
  name_prefix           = "${var.name_prefix}-${var.environment}"
  environment           = var.environment
  project               = var.project
  tags                  = local.common_tags
  trusted_role_services = ["lambda.amazonaws.com"]
  inline_policies       = local.service_b_inline_policies
}

module "service_a_role" {
  source = "../../tf-aws-iam-role"

  providers = {
    aws = aws.central
  }

  name              = "service-a-role"
  name_prefix       = "${var.name_prefix}-${var.environment}"
  environment       = var.environment
  project           = var.project
  tags              = local.common_tags
  trusted_role_arns = [module.service_b_role.role_arn]
  inline_policies = {
    kms_alias_access = local.service_a_inline_policy
  }
}

module "tenant_keys" {
  source = "../../tf-aws-kms"

  providers = {
    aws = aws.central
  }

  name_prefix = "${var.name_prefix}-${var.environment}"
  tags        = local.common_tags
  keys        = local.tenant_keys
}

module "service_b_lambda" {
  source = "../../tf-aws-lambda"

  providers = {
    aws = aws.workload
  }

  function_name     = "tenant-encryptor"
  name_prefix       = "${var.name_prefix}-${var.environment}"
  environment       = var.environment
  project           = var.project
  tags              = local.common_tags
  create_role       = false
  role_arn          = module.service_b_role.role_arn
  filename          = data.archive_file.tenant_encryptor.output_path
  source_code_hash  = data.archive_file.tenant_encryptor.output_base64sha256
  handler           = "tenant_encryptor.handler"
  runtime           = "python3.12"
  timeout           = 30
  memory_size       = 256
  publish           = true
  tracing_mode      = "Active"
  log_retention_days = 30

  environment_variables = {
    DDB_TABLE_NAME       = module.tenant_data.table_names["tenant_data"]
    SERVICE_A_ROLE_ARN   = module.service_a_role.role_arn
    CENTRAL_KMS_REGION   = var.central_region
  }
}
