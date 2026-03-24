aws_region            = "us-east-1"
name                  = "data-processor"
name_prefix           = "prod"
environment           = "prod"
project               = "analytics"
owner                 = "data-team"
cost_center           = "CC-300"
description           = "Role for data processing Lambda functions"
max_session_duration  = 7200
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
  "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
]
s3_data_bucket = "my-data-bucket-prod"
tags           = { Environment = "prod", Compliance = "SOC2" }
