# staging — dedicated VPC
aws_region  = "us-east-1"
name        = "platform"
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

vpc_id                     = "vpc-0stagingshared"
default_subnet_ids         = ["subnet-0stg1", "subnet-0stg2"]
default_security_group_ids = ["sg-0endpoints-stg"]
default_route_table_ids    = ["rtb-0stg1", "rtb-0stg2"]

endpoints = {
  s3 = {
    service_name      = "s3"
    vpc_endpoint_type = "Gateway"
  }
  dynamodb = {
    service_name      = "dynamodb"
    vpc_endpoint_type = "Gateway"
  }
  ssm = {
    service_name = "ssm"
    private_dns  = true
  }
  ssm_messages = {
    service_name = "ssmmessages"
    private_dns  = true
  }
  ec2_messages = {
    service_name = "ec2messages"
    private_dns  = true
  }
  secretsmanager = {
    service_name = "secretsmanager"
    private_dns  = true
  }
  kms = {
    service_name = "kms"
    private_dns  = true
  }
  ecr_api = {
    service_name = "ecr.api"
    private_dns  = true
  }
  ecr_dkr = {
    service_name = "ecr.dkr"
    private_dns  = true
  }
}
