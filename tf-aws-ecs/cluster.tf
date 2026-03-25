# ---------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  dynamic "configuration" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.kms_key_arn
        logging    = "OVERRIDE"
        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = "/aws/ecs/${local.name}"
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Capacity Providers
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = compact([
    var.use_fargate ? "FARGATE" : null,
    var.use_fargate_spot ? "FARGATE_SPOT" : null,
  ])

  dynamic "default_capacity_provider_strategy" {
    for_each = var.use_fargate ? [1] : []
    content {
      capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
      weight            = 1
      base              = 1
    }
  }
}
