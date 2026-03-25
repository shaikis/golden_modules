# ── Event Source Mappings (SQS, DynamoDB, Kinesis, MSK, MQ) ──────────────────
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.event_source_mappings

  event_source_arn                   = each.value.event_source_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = each.value.batch_size
  maximum_batching_window_in_seconds = each.value.maximum_batching_window_in_seconds
  starting_position                  = each.value.starting_position
  starting_position_timestamp        = each.value.starting_position_timestamp
  enabled                            = each.value.enabled
  bisect_batch_on_function_error     = each.value.bisect_batch_on_function_error
  maximum_retry_attempts             = each.value.maximum_retry_attempts
  tumbling_window_in_seconds         = each.value.tumbling_window_in_seconds
  parallelization_factor             = each.value.parallelization_factor
  function_response_types            = each.value.function_response_types

  dynamic "filter_criteria" {
    for_each = length(each.value.filter_criteria) > 0 ? [1] : []
    content {
      dynamic "filter" {
        for_each = each.value.filter_criteria
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }

  dynamic "destination_config" {
    for_each = each.value.destination_config != null ? [each.value.destination_config] : []
    content {
      dynamic "on_failure" {
        for_each = destination_config.value.on_failure_destination_arn != null ? [1] : []
        content {
          destination_arn = destination_config.value.on_failure_destination_arn
        }
      }
    }
  }
}

# ── Resource-based Permissions (triggers) ─────────────────────────────────────
resource "aws_lambda_permission" "this" {
  for_each = var.allowed_triggers

  statement_id   = each.key
  action         = each.value.action
  function_name  = aws_lambda_function.this.function_name
  qualifier      = each.value.qualifier
  principal      = each.value.principal
  source_arn     = each.value.source_arn
  source_account = each.value.source_account
}
