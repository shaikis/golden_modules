provider "aws" { region = var.aws_region }

module "ecs" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  tags        = var.tags

  task_definitions = {
    web = {
      cpu    = var.task_cpu
      memory = var.task_memory
      container_definitions = jsonencode([{
        name      = "web"
        image     = var.container_image
        essential = true
        portMappings = [{
          containerPort = var.container_port
          protocol      = "tcp"
        }]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.name}-web"
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }])
    }
  }

  services = {
    web = {
      task_definition_key = "web"
      desired_count       = var.desired_count
      network_configuration = {
        subnets         = var.service_subnets
        security_groups = var.service_security_groups
      }
    }
  }
}

output "cluster_arn" { value = module.ecs.cluster_arn }
