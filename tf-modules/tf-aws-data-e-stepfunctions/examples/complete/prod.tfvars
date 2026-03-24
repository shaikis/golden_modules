aws_region  = "us-east-1"
name_prefix = "prod-"

alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:prod-alerts"

lambda_function_arns = [
  "arn:aws:lambda:us-east-1:123456789012:function:validate-event",
  "arn:aws:lambda:us-east-1:123456789012:function:process-purchase",
  "arn:aws:lambda:us-east-1:123456789012:function:process-clickstream",
  "arn:aws:lambda:us-east-1:123456789012:function:process-generic-event",
  "arn:aws:lambda:us-east-1:123456789012:function:check-s3-data-availability",
  "arn:aws:lambda:us-east-1:123456789012:function:evaluate-model-metrics",
]

tags = {
  Environment = "prod"
  Team        = "data-engineering"
  CostCenter  = "DE-001"
  ManagedBy   = "terraform"
  Module      = "tf-aws-data-e-stepfunctions"
}
