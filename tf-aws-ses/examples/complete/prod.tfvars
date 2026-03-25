aws_region = "us-east-1"

inbound_bucket_name = "acme-ses-inbound-mail-prod-us-east-1"

sns_bounce_topic_arn = "arn:aws:sns:us-east-1:123456789012:ses-bounces-complaints-prod"

sns_inbound_topic_arn = "arn:aws:sns:us-east-1:123456789012:ses-inbound-mail-prod"

firehose_stream_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/ses-marketing-events-prod"

inbound_processor_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:ses-inbound-processor-prod"

tags = {
  Project     = "email-platform"
  Environment = "production"
  Owner       = "platform-team"
  CostCenter  = "engineering"
  ManagedBy   = "terraform"
}
