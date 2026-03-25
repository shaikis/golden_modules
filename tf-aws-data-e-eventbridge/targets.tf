locals {
  effective_role_arn = var.create_iam_role ? try(aws_iam_role.eventbridge[0].arn, null) : var.role_arn
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.targets

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_key].name
  event_bus_name = aws_cloudwatch_event_rule.this[each.value.rule_key].event_bus_name
  target_id      = coalesce(each.value.target_id, each.key)
  arn            = each.value.arn
  role_arn       = coalesce(each.value.role_arn, local.effective_role_arn)

  input      = each.value.input
  input_path = each.value.input_path

  dynamic "input_transformer" {
    for_each = each.value.input_transformer != null ? [each.value.input_transformer] : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }

  dynamic "sqs_target" {
    for_each = each.value.sqs_message_group_id != null ? [1] : []
    content {
      message_group_id = each.value.sqs_message_group_id
    }
  }

  dynamic "kinesis_target" {
    for_each = each.value.kinesis_partition_key != null ? [1] : []
    content {
      partition_key_path = each.value.kinesis_partition_key
    }
  }

  dynamic "retry_policy" {
    for_each = (each.value.retry_attempts != null || each.value.max_event_age_seconds != null) ? [1] : []
    content {
      maximum_retry_attempts       = each.value.retry_attempts
      maximum_event_age_in_seconds = each.value.max_event_age_seconds
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_queue_arn != null ? [1] : []
    content {
      arn = each.value.dead_letter_queue_arn
    }
  }

  dynamic "ecs_target" {
    for_each = each.value.ecs_target != null ? [each.value.ecs_target] : []
    content {
      task_definition_arn = ecs_target.value.task_definition_arn
      task_count          = ecs_target.value.task_count
      launch_type         = ecs_target.value.launch_type

      network_configuration {
        subnets          = ecs_target.value.subnet_ids
        security_groups  = ecs_target.value.security_group_ids
        assign_public_ip = ecs_target.value.assign_public_ip
      }

      dynamic "container_overrides" {
        for_each = ecs_target.value.container_overrides
        content {
          name    = container_overrides.value.name
          command = container_overrides.value.command

          dynamic "environment" {
            for_each = container_overrides.value.environment
            content {
              name  = environment.key
              value = environment.value
            }
          }
        }
      }
    }
  }

  depends_on = [aws_cloudwatch_event_rule.this]
}
