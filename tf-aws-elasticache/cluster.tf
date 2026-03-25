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
