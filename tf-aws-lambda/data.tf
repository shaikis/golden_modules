data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Lambda Insights layer ARN (AWS-managed, region-specific)
data "aws_lambda_layer_version" "insights" {
  count      = var.enable_lambda_insights ? 1 : 0
  layer_name = "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:580247275435:layer:LambdaInsightsExtension"
  version    = var.lambda_insights_version
}
