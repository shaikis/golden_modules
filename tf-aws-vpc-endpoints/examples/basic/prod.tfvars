# prod — dedicated VPC, full endpoint set
aws_region  = "us-east-1"
name        = "platform"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

vpc_id                     = "vpc-0prodonly"
default_subnet_ids         = ["subnet-0prod1", "subnet-0prod2", "subnet-0prod3"]
default_security_group_ids = ["sg-0endpoints-prod"]
default_route_table_ids    = ["rtb-0prod1", "rtb-0prod2", "rtb-0prod3"]

endpoints = {
  s3       = { service_name = "s3";       vpc_endpoint_type = "Gateway" }
  dynamodb = { service_name = "dynamodb"; vpc_endpoint_type = "Gateway" }

  ssm          = { service_name = "ssm";          private_dns = true }
  ssm_messages = { service_name = "ssmmessages";  private_dns = true }
  ec2_messages = { service_name = "ec2messages";  private_dns = true }
  ec2          = { service_name = "ec2";           private_dns = true }

  secretsmanager = { service_name = "secretsmanager"; private_dns = true }
  kms            = { service_name = "kms";             private_dns = true }

  ecr_api = { service_name = "ecr.api"; private_dns = true }
  ecr_dkr = { service_name = "ecr.dkr"; private_dns = true }

  logs      = { service_name = "logs";      private_dns = true }
  monitoring = { service_name = "monitoring"; private_dns = true }
  events    = { service_name = "events";    private_dns = true }

  sqs = { service_name = "sqs"; private_dns = true }
  sns = { service_name = "sns"; private_dns = true }

  sts = { service_name = "sts"; private_dns = true }

  # EKS: required for private cluster control plane communication
  eks = { service_name = "eks"; private_dns = true }
}
