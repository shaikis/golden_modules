resource "aws_cloudwatch_event_api_destination" "this" {
  for_each = var.create_api_destinations ? var.api_destinations : {}

  name                             = each.key
  description                      = each.value.description
  connection_arn                   = aws_cloudwatch_event_connection.this[each.value.connection_key].arn
  invocation_endpoint              = each.value.invocation_endpoint
  http_method                      = each.value.http_method
  invocation_rate_limit_per_second = each.value.invocation_rate_limit_per_second

  depends_on = [aws_cloudwatch_event_connection.this]
}
