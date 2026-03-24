# ---------------------------------------------------------------------------
# Subnet Group
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  count = var.subnet_group_name == null && length(var.subnet_ids) > 0 ? 1 : 0

  name        = "${local.name}-sg"
  description = "ElastiCache subnet group for ${local.name}"
  subnet_ids  = var.subnet_ids

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Parameter Group
# ---------------------------------------------------------------------------
resource "aws_elasticache_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${local.name}-pg"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags

  lifecycle { create_before_destroy = true }
}

# ---------------------------------------------------------------------------
# Redis Replication Group
# ---------------------------------------------------------------------------
resource "aws_elasticache_replication_group" "this" {
  count = var.engine == "redis" ? 1 : 0

  replication_group_id = local.name
  description          = "${local.name} Redis replication group"

  node_type      = var.node_type
  engine_version = var.engine_version
  port           = var.port

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Cluster mode disabled (single shard)
  num_cache_clusters = var.num_node_groups == 1 ? var.num_cache_clusters : null

  # Cluster mode enabled (multiple shards)
  num_node_groups         = var.num_node_groups > 1 ? var.num_node_groups : null
  replicas_per_node_group = var.num_node_groups > 1 ? var.replicas_per_node_group : null

  subnet_group_name  = var.subnet_group_name != null ? var.subnet_group_name : try(aws_elasticache_subnet_group.this[0].name, null)
  security_group_ids = var.security_group_ids

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null
  kms_key_id                 = var.kms_key_id

  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  notification_topic_arn     = var.notification_topic_arn

  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : null

  preferred_cache_cluster_azs = var.preferred_cache_cluster_azs

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configurations
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [auth_token, tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Memcached Cluster
# ---------------------------------------------------------------------------
resource "aws_elasticache_cluster" "memcached" {
  count = var.engine == "memcached" ? 1 : 0

  cluster_id      = local.name
  engine          = "memcached"
  engine_version  = var.engine_version
  node_type       = var.node_type
  num_cache_nodes = var.num_cache_nodes
  port            = 11211

  subnet_group_name  = var.subnet_group_name != null ? var.subnet_group_name : try(aws_elasticache_subnet_group.this[0].name, null)
  security_group_ids = var.security_group_ids

  availability_zone            = length(var.availability_zones) > 0 ? var.availability_zones[0] : null
  preferred_availability_zones = var.availability_zones
  maintenance_window           = var.maintenance_window
  apply_immediately            = var.apply_immediately
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade

  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : null

  notification_topic_arn = var.notification_topic_arn

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}
