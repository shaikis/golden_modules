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

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.name}-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.name}-worker"
  retention_in_days = 30
}

module "efs" {
  source = "../../../tf-aws-efs"

  name        = "${var.name}-shared"
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  create_security_group = false
  vpc_id                = var.vpc_id
  subnet_ids            = var.efs_subnet_ids
  security_group_ids    = []

  create = true
  access_points = {
    app = {
      path        = "/app"
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
      posix_uid   = 1000
      posix_gid   = 1000
    }
  }
}

module "ecs" {
  source = "../../"

  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  use_fargate      = true
  use_fargate_spot = true

  task_definitions = {
    api = {
      cpu    = 512
      memory = 1024
      container_definitions = jsonencode([{
        name      = "api"
        image     = var.api_image
        essential = true
        portMappings = [{
          containerPort = 8080
          protocol      = "tcp"
        }]
        mountPoints = [{
          sourceVolume  = "shared-data"
          containerPath = "/data"
          readOnly      = false
        }]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.api.name
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }])

      volumes = [{
        name = "shared-data"
        efs_volume_configuration = {
          file_system_id     = module.efs.file_system_id
          root_directory     = "/"
          transit_encryption = "ENABLED"
          authorization_config = {
            access_point_id = module.efs.access_point_ids["app"]
            iam             = "ENABLED"
          }
        }
      }]
    }

    worker = {
      cpu    = 256
      memory = 512
      container_definitions = jsonencode([{
        name      = "worker"
        image     = var.worker_image
        essential = true
        command   = ["sh", "-c", "while true; do echo processing; sleep 30; done"]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.worker.name
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }])
    }
  }

  services = {
    api = {
      task_definition_key    = "api"
      desired_count          = 2
      enable_execute_command = true
      network_configuration = {
        subnets          = var.service_subnet_ids
        security_groups  = var.service_security_group_ids
        assign_public_ip = false
      }
      capacity_provider_strategy = [
        {
          capacity_provider = "FARGATE"
          weight            = 1
          base              = 1
        },
        {
          capacity_provider = "FARGATE_SPOT"
          weight            = 1
          base              = 0
        }
      ]
    }

    worker = {
      task_definition_key    = "worker"
      desired_count          = 1
      enable_execute_command = true
      network_configuration = {
        subnets          = var.service_subnet_ids
        security_groups  = var.service_security_group_ids
        assign_public_ip = false
      }
      capacity_provider_strategy = [
        {
          capacity_provider = "FARGATE_SPOT"
          weight            = 1
          base              = 0
        }
      ]
    }
  }
}
