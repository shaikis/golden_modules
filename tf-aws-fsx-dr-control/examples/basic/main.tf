terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "fsx_dr_control" {
  source = "../../"

  name        = var.name
  environment = var.environment
  project     = var.project

  allowed_secret_arns = var.allowed_secret_arns

  dns = {
    zone_id     = var.route53_zone_id
    record_name = var.route53_record_name
    record_type = "CNAME"
    ttl         = 30
  }

  lambda_subnet_ids         = var.lambda_subnet_ids
  lambda_security_group_ids = var.lambda_security_group_ids
  notification_topic_arn    = var.notification_topic_arn
}

output "state_machine_arn" {
  value = module.fsx_dr_control.state_machine_arn
}

output "switchover_execution_example" {
  value = module.fsx_dr_control.switchover_execution_example
}
