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

module "nlb" {
  source = "../../"

  name               = var.name
  environment        = var.environment
  load_balancer_type = "network"
  internal           = var.internal
  vpc_id             = var.vpc_id
  subnets            = var.subnets

  enable_deletion_protection = false

  target_groups = {
    tcp_app = {
      port        = var.target_port
      protocol    = "TCP"
      target_type = "instance"
      health_check = {
        protocol = "TCP"
        port     = "traffic-port"
      }
      attachments = [
        for instance_id in var.instance_ids : {
          target_id = instance_id
          port      = var.target_port
        }
      ]
    }
  }

  listeners = {
    tcp = {
      port     = var.listener_port
      protocol = "TCP"
      default_action = {
        type             = "forward"
        target_group_key = "tcp_app"
      }
    }
  }

  tags = var.tags
}
