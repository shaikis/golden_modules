aws_region  = "us-east-1"
vpc_id      = "vpc-0abc123456789def0"
subnet_ids  = ["subnet-0abc123456789def0", "subnet-0def123456789abc0"]
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:ml-platform-alerts"

data_bucket_arns = [
  "arn:aws:s3:::my-data-bucket",
  "arn:aws:s3:::my-models-bucket",
]

offline_feature_store_bucket = "my-feature-store-bucket"
