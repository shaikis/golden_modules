aws_region            = "us-east-1"
name                  = "data-processor"
name_prefix           = "dev"
environment           = "dev"
project               = "analytics"
owner                 = "data-team"
cost_center           = "CC-300"
description           = "Role for data processing Lambda functions"
max_session_duration  = 3600
trusted_role_services = ["lambda.amazonaws.com"]
assume_role_conditions = [
  {
    test     = "StringEquals"
    variable = "aws:RequestedRegion"
    values   = ["us-east-1"]
  }
]
managed_policy_arns = [
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
]
s3_data_bucket = "my-data-bucket-dev"
tags           = { Environment = "dev", Compliance = "internal" }
