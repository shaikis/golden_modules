# ---------------------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier        = var.identifier_prefix != null ? null : local.name
  identifier_prefix = var.identifier_prefix

  # Engine
  engine                      = var.engine
  engine_version              = local.resolved_engine_version
  instance_class              = var.instance_class
  license_model               = var.license_model
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  ca_cert_identifier          = var.ca_cert_identifier
  character_set_name          = var.character_set_name
  nchar_character_set_name    = var.nchar_character_set_name
  timezone                    = var.timezone
  network_type                = var.network_type

  # RDS Custom
  custom_iam_instance_profile = var.custom_iam_instance_profile

  # Database
  db_name                       = var.db_name
  username                      = var.replicate_source_db != null ? null : var.username
  password                      = var.manage_master_user_password || var.replicate_source_db != null ? null : var.password
  manage_master_user_password   = var.replicate_source_db != null ? null : var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  port                          = var.port

  # IAM Authentication (MySQL, PostgreSQL)
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Replica
  replicate_source_db = var.replicate_source_db
  replica_mode        = var.replica_mode

  # Snapshot / PITR restore (mutually exclusive — set only one)
  snapshot_identifier = var.snapshot_identifier

  # Storage
  allocated_storage     = var.snapshot_identifier != null || var.restore_to_point_in_time != null ? null : var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  dedicated_log_volume  = var.dedicated_log_volume
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.multi_az ? null : var.availability_zone
  multi_az               = var.multi_az

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.name}"
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  delete_automated_backups  = var.delete_automated_backups

  # Protection
  deletion_protection = var.deletion_protection

  # Monitoring
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? try(aws_iam_role.monitoring[0].arn, var.monitoring_role_arn) : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  # Parameters & Options
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Active Directory / Domain Join (SQL Server Windows Authentication)
  domain                 = var.domain
  domain_fqdn            = var.domain_fqdn
  domain_dns_ips         = var.domain_dns_ips
  domain_ou              = var.domain_ou
  domain_auth_secret_arn = var.domain_auth_secret_arn
  domain_iam_role_name = (var.domain != null || var.domain_fqdn != null) ? (
    var.create_domain_iam_role
    ? aws_iam_role.domain[0].name
    : var.domain_iam_role_name
  ) : null

  # Blue/Green deployment (zero-downtime upgrades)
  dynamic "blue_green_update" {
    for_each = var.blue_green_update != null ? [var.blue_green_update] : []
    content {
      enabled = blue_green_update.value.enabled
    }
  }

  # S3 Import — MySQL bulk load from Percona XtraBackup
  dynamic "s3_import" {
    for_each = var.s3_import != null ? [var.s3_import] : []
    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = s3_import.value.bucket_prefix
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = s3_import.value.source_engine
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  # Point-in-Time Restore
  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []
    content {
      restore_time                             = restore_to_point_in_time.value.restore_time
      source_db_instance_identifier            = restore_to_point_in_time.value.source_db_instance_identifier
      source_db_instance_automated_backups_arn = restore_to_point_in_time.value.source_db_instance_automated_backups_arn
      source_dbi_resource_id                   = restore_to_point_in_time.value.source_dbi_resource_id
      use_latest_restorable_time               = restore_to_point_in_time.value.use_latest_restorable_time
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [password, tags["CreatedDate"]]

    precondition {
      condition     = !local.is_sqlserver_developer || var.license_model == "bring-your-own-license"
      error_message = "SQL Server Developer Edition on RDS requires license_model = \"bring-your-own-license\"."
    }

    precondition {
      condition     = !local.is_sqlserver_developer || !var.multi_az
      error_message = "SQL Server Developer Edition on RDS does not support Multi-AZ deployments."
    }

    precondition {
      condition     = !local.is_sqlserver_developer || var.replicate_source_db == null
      error_message = "SQL Server Developer Edition on RDS does not support read replicas."
    }

    precondition {
      condition     = !local.is_sqlserver_developer || can(regex("^db\\.(m6i|r6i)\\.", var.instance_class))
      error_message = "SQL Server Developer Edition on RDS is currently supported only on db.m6i.* and db.r6i.* instance classes."
    }

    precondition {
      condition     = !local.is_sqlserver_developer || var.db_name == null
      error_message = "For SQL Server Developer Edition, set db_name = null and create databases after the instance is provisioned."
    }

    precondition {
      condition     = local.is_sqlserver_developer || !var.create_sqlserver_developer_custom_engine_version
      error_message = "create_sqlserver_developer_custom_engine_version can only be used when engine = \"sqlserver-dev-ee\"."
    }
  }

  depends_on = [
    null_resource.sqlserver_developer_custom_engine_version
  ]
}
