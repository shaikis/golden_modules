# ---------------------------------------------------------------------------
# Auto Scaling for Read Replicas
# ---------------------------------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.this.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity

  depends_on = [aws_rds_cluster_instance.this]
}

resource "aws_appautoscaling_policy" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "${local.name}-aurora-autoscaling"
  policy_type        = var.autoscaling_policy_type
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value       = var.autoscaling_target_cpu
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}
