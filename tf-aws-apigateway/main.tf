locals {
  name_prefix = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  common_tags = merge(var.tags, {
    Name        = local.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.name_prefix
  description   = var.description
  protocol_type = var.protocol_type
  tags          = local.common_tags

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_headers  = cors_configuration.value.allow_headers
      allow_methods  = cors_configuration.value.allow_methods
      allow_origins  = cors_configuration.value.allow_origins
      expose_headers = cors_configuration.value.expose_headers
      max_age        = cors_configuration.value.max_age
    }
  }
}

resource "aws_cloudwatch_log_group" "access_logs" {
  count             = var.enable_access_logs ? 1 : 0
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy
  tags        = local.common_tags

  dynamic "access_log_settings" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.access_logs[0].arn
    }
  }

  default_route_settings {
    throttling_burst_limit   = var.default_route_settings.throttling_burst_limit
    throttling_rate_limit    = var.default_route_settings.throttling_rate_limit
    detailed_metrics_enabled = var.default_route_settings.detailed_metrics_enabled
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each               = var.routes
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = each.value.timeout_milliseconds
}

resource "aws_apigatewayv2_route" "this" {
  for_each           = var.routes
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorizer_id
}

resource "aws_lambda_permission" "apigw" {
  for_each      = var.routes
  statement_id  = "AllowAPIGatewayInvoke-${replace(each.key, "/[^a-zA-Z0-9]/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
