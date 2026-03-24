# ---------------------------------------------------------------------------
# Application Auto Scaling for DynamoDB (PROVISIONED tables only)
# ---------------------------------------------------------------------------

locals {
  # Tables that have PROVISIONED billing and a non-null autoscaling block
  autoscaling_tables = {
    for k, v in var.tables : k => v
    if v.billing_mode == "PROVISIONED" && v.autoscaling != null
  }

  # Flatten GSI autoscaling entries across all autoscaling-enabled tables
  autoscaling_gsis = merge([
    for table_key, table in local.autoscaling_tables : {
      for gsi in table.global_secondary_indexes :
      "${table_key}__${gsi.name}" => {
        table_key  = table_key
        table_name = aws_dynamodb_table.this[table_key].name
        gsi_name   = gsi.name
        autoscaling = gsi.autoscaling != null ? gsi.autoscaling : {
          min_read_capacity        = 1
          max_read_capacity        = 100
          min_write_capacity       = 1
          max_write_capacity       = 100
          target_read_utilization  = 70
          target_write_utilization = 70
        }
      }
      if gsi.autoscaling != null
    }
  ]...)
}

# ---------------------------------------------------------------------------
# Table-level: Read Capacity
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "table_read" {
  for_each = local.autoscaling_tables

  service_namespace  = "dynamodb"
  resource_id        = "table/${aws_dynamodb_table.this[each.key].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  min_capacity       = each.value.autoscaling.min_read_capacity
  max_capacity       = each.value.autoscaling.max_read_capacity
}

resource "aws_appautoscaling_policy" "table_read" {
  for_each = local.autoscaling_tables

  name               = "${aws_dynamodb_table.this[each.key].name}-read-scaling"
  service_namespace  = "dynamodb"
  resource_id        = aws_appautoscaling_target.table_read[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.table_read[each.key].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value       = each.value.autoscaling.target_read_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ---------------------------------------------------------------------------
# Table-level: Write Capacity
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "table_write" {
  for_each = local.autoscaling_tables

  service_namespace  = "dynamodb"
  resource_id        = "table/${aws_dynamodb_table.this[each.key].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  min_capacity       = each.value.autoscaling.min_write_capacity
  max_capacity       = each.value.autoscaling.max_write_capacity
}

resource "aws_appautoscaling_policy" "table_write" {
  for_each = local.autoscaling_tables

  name               = "${aws_dynamodb_table.this[each.key].name}-write-scaling"
  service_namespace  = "dynamodb"
  resource_id        = aws_appautoscaling_target.table_write[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.table_write[each.key].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value       = each.value.autoscaling.target_write_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ---------------------------------------------------------------------------
# GSI-level: Read Capacity
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "gsi_read" {
  for_each = local.autoscaling_gsis

  service_namespace  = "dynamodb"
  resource_id        = "table/${each.value.table_name}/index/${each.value.gsi_name}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  min_capacity       = each.value.autoscaling.min_read_capacity
  max_capacity       = each.value.autoscaling.max_read_capacity
}

resource "aws_appautoscaling_policy" "gsi_read" {
  for_each = local.autoscaling_gsis

  name               = "${each.value.table_name}-${each.value.gsi_name}-read-scaling"
  service_namespace  = "dynamodb"
  resource_id        = aws_appautoscaling_target.gsi_read[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_read[each.key].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value       = each.value.autoscaling.target_read_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ---------------------------------------------------------------------------
# GSI-level: Write Capacity
# ---------------------------------------------------------------------------

resource "aws_appautoscaling_target" "gsi_write" {
  for_each = local.autoscaling_gsis

  service_namespace  = "dynamodb"
  resource_id        = "table/${each.value.table_name}/index/${each.value.gsi_name}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  min_capacity       = each.value.autoscaling.min_write_capacity
  max_capacity       = each.value.autoscaling.max_write_capacity
}

resource "aws_appautoscaling_policy" "gsi_write" {
  for_each = local.autoscaling_gsis

  name               = "${each.value.table_name}-${each.value.gsi_name}-write-scaling"
  service_namespace  = "dynamodb"
  resource_id        = aws_appautoscaling_target.gsi_write[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_write[each.key].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value       = each.value.autoscaling.target_write_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
