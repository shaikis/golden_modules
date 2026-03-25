# dev / staging / qa — shared VPC (same vpc_id for lower envs)
aws_region  = "us-east-1"
name        = "platform"
environment = "dev"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

vpc_id                     = "vpc-0devshared" # shared lower-env VPC
default_subnet_ids         = ["subnet-0dev1", "subnet-0dev2"]
default_security_group_ids = ["sg-0endpoints"]
default_route_table_ids    = ["rtb-0dev1", "rtb-0dev2"]

endpoints = {
  # Gateway (free) — S3 + DynamoDB
  s3 = {
    service_name      = "s3"
    vpc_endpoint_type = "Gateway"
  }
  dynamodb = {
    service_name      = "dynamodb"
    vpc_endpoint_type = "Gateway"
  }

  # Interface — SSM (required for Systems Manager without internet)
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

  # Secrets Manager + KMS
  secretsmanager = {
    service_name = "secretsmanager"
    private_dns  = true
  }
  kms = {
    service_name = "kms"
    private_dns  = true
  }

  # ECR (for EKS / ECS pulling images without NAT)
  ecr_api = {
    service_name = "ecr.api"
    private_dns  = true
  }
  ecr_dkr = {
    service_name = "ecr.dkr"
    private_dns  = true
  }
}
