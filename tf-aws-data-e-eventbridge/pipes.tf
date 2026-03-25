locals {
  effective_pipes_role_arn = var.create_iam_role ? try(aws_iam_role.eventbridge_pipes[0].arn, null) : var.role_arn
}

resource "aws_pipes_pipe" "this" {
  for_each = var.create_pipes ? var.pipes : {}

  name        = each.key
  description = each.value.description
  role_arn    = coalesce(each.value.role_arn, local.effective_pipes_role_arn)

  source = each.value.source
  target = each.value.target

  desired_state = each.value.desired_state

  dynamic "source_parameters" {
    for_each = each.value.source_parameters != null ? [each.value.source_parameters] : []
    content {
      dynamic "filter_criteria" {
        for_each = source_parameters.value.filter_criteria != null ? [source_parameters.value.filter_criteria] : []
        content {
          dynamic "filter" {
            for_each = filter_criteria.value.filters
            content {
              pattern = filter.value.pattern
            }
          }
        }
      }

      dynamic "dynamodb_stream_parameters" {
        for_each = source_parameters.value.dynamodb_stream_parameters != null ? [source_parameters.value.dynamodb_stream_parameters] : []
        content {
          starting_position                  = dynamodb_stream_parameters.value.starting_position
          batch_size                         = dynamodb_stream_parameters.value.batch_size
          maximum_batching_window_in_seconds = dynamodb_stream_parameters.value.maximum_batching_window_in_seconds
          maximum_retry_attempts             = dynamodb_stream_parameters.value.maximum_retry_attempts
        }
      }

      dynamic "kinesis_stream_parameters" {
        for_each = source_parameters.value.kinesis_stream_parameters != null ? [source_parameters.value.kinesis_stream_parameters] : []
        content {
          starting_position                  = kinesis_stream_parameters.value.starting_position
          batch_size                         = kinesis_stream_parameters.value.batch_size
          maximum_batching_window_in_seconds = kinesis_stream_parameters.value.maximum_batching_window_in_seconds
        }
      }

      dynamic "sqs_queue_parameters" {
        for_each = source_parameters.value.sqs_queue_parameters != null ? [source_parameters.value.sqs_queue_parameters] : []
        content {
          batch_size                         = sqs_queue_parameters.value.batch_size
          maximum_batching_window_in_seconds = sqs_queue_parameters.value.maximum_batching_window_in_seconds
        }
      }
    }
  }

  enrichment = each.value.enrichment

  dynamic "enrichment_parameters" {
    for_each = each.value.enrichment_input_template != null ? [1] : []
    content {
      input_template = each.value.enrichment_input_template
    }
  }

  dynamic "target_parameters" {
    for_each = each.value.target_parameters != null ? [each.value.target_parameters] : []
    content {
      input_template = target_parameters.value.input_template

      dynamic "sqs_queue_parameters" {
        for_each = target_parameters.value.sqs_queue_parameters != null ? [target_parameters.value.sqs_queue_parameters] : []
        content {
          message_group_id = sqs_queue_parameters.value.message_group_id
        }
      }

      dynamic "lambda_function_parameters" {
        for_each = target_parameters.value.lambda_function_parameters != null ? [target_parameters.value.lambda_function_parameters] : []
        content {
          invocation_type = lambda_function_parameters.value.invocation_type
        }
      }

      dynamic "step_function_state_machine_parameters" {
        for_each = target_parameters.value.step_function_state_machine_parameters != null ? [target_parameters.value.step_function_state_machine_parameters] : []
        content {
          invocation_type = step_function_state_machine_parameters.value.invocation_type
        }
      }
    }
  }

  tags = merge(var.tags, each.value.tags)

  depends_on = [aws_cloudwatch_event_bus.this]
}
