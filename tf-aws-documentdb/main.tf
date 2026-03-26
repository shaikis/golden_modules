locals {
  name_prefix = "${var.name}-${var.environment}"

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  final_snapshot_id = var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${local.name_prefix}-final-snapshot"
}

# ── Random password (when not provided) ────────────────────────────────────────
resource "random_password" "master" {
  count   = var.master_password == null ? 1 : 0
  length  = 32
  special = false # DocumentDB does not support all special chars
}

locals {
  master_password = var.master_password != null ? var.master_password : random_password.master[0].result
}

# ── Secrets Manager — master credentials ───────────────────────────────────────
resource "aws_secretsmanager_secret" "docdb_credentials" {
  name        = "${local.name_prefix}-docdb-credentials"
  description = "DocumentDB master credentials for ${local.name_prefix}"
  kms_key_id  = var.kms_key_id
  tags        = local.common_tags

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "docdb_credentials" {
  secret_id = aws_secretsmanager_secret.docdb_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = local.master_password
    host     = aws_docdb_cluster.this.endpoint
    port     = var.port
    dbname   = "horde"
    uri      = "mongodb://${var.master_username}:${local.master_password}@${aws_docdb_cluster.this.endpoint}:${var.port}/?tls=true&tlsCAFile=/etc/ssl/certs/rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  })
}

# ── Security Group ─────────────────────────────────────────────────────────────
resource "aws_security_group" "docdb" {
  name        = "${local.name_prefix}-docdb-sg"
  description = "Security group for ${local.name_prefix} DocumentDB cluster"
  vpc_id      = var.vpc_id
  tags        = local.common_tags

  ingress {
    description     = "DocumentDB from allowed security groups"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── Subnet Group ───────────────────────────────────────────────────────────────
resource "aws_docdb_subnet_group" "this" {
  name        = "${local.name_prefix}-subnet-group"
  description = "DocumentDB subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids
  tags        = local.common_tags
}

# ── Parameter Group ────────────────────────────────────────────────────────────
resource "aws_docdb_cluster_parameter_group" "this" {
  name        = "${local.name_prefix}-params"
  family      = "docdb${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}"
  description = "Parameter group for ${local.name_prefix} DocumentDB cluster"
  tags        = local.common_tags

  parameter {
    name  = "tls"
    value = var.tls_enabled ? "enabled" : "disabled"
  }

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

# ── CloudWatch Log Groups ───────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "docdb" {
  for_each = toset(var.enabled_cloudwatch_logs)

  name              = "/aws/docdb/${local.name_prefix}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id
  tags              = local.common_tags
}

# ── DocumentDB Cluster ─────────────────────────────────────────────────────────
resource "aws_docdb_cluster" "this" {
  cluster_identifier              = local.name_prefix
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = local.master_password
  port                            = var.port
  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : local.final_snapshot_id
  deletion_protection          = var.deletion_protection
  apply_immediately            = var.apply_immediately

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.docdb]
}

# ── DocumentDB Cluster Instances ───────────────────────────────────────────────
resource "aws_docdb_cluster_instance" "this" {
  count = var.cluster_size

  identifier         = "${local.name_prefix}-${count.index}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.instance_class
  engine             = "docdb"
  promotion_tier     = count.index # 0 = primary preferred, higher = less preferred for failover

  apply_immediately            = var.apply_immediately
  preferred_maintenance_window = var.preferred_maintenance_window

  tags = merge(local.common_tags, {
    Role = count.index == 0 ? "primary" : "reader"
  })
}
