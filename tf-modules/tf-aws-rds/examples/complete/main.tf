provider "aws" { region = var.aws_region }

module "kms" { source = "../../../tf-aws-kms"; name = "rds-${var.environment}"; environment = var.environment }

module "rds" {
  source      = "../../"
  name        = var.name
  name_prefix = var.name_prefix
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = module.kms.key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = module.kms.key_arn

  multi_az               = var.multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  monitoring_interval                   = var.monitoring_interval
  create_monitoring_role                = var.create_monitoring_role
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = module.kms.key_arn
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  create_parameter_group = var.create_parameter_group
  parameter_group_family = var.parameter_group_family
  parameters             = var.parameters

  tags = var.tags
}

output "endpoint"   { value = module.rds.db_instance_endpoint }
output "secret_arn" { value = module.rds.db_master_user_secret_arn }
