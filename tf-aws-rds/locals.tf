locals {
  name                   = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name
  is_sqlserver_developer = var.engine == "sqlserver-dev-ee"
  resolved_engine_version = (
    var.create_sqlserver_developer_custom_engine_version
    ? var.sqlserver_developer_custom_engine_version_name
    : var.engine_version
  )

  default_tags = {
    Name        = local.name
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Module      = "tf-aws-rds"
  }
  tags = merge(local.default_tags, var.tags)
}
