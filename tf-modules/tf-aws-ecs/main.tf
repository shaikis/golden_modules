data "aws_partition" "current" {}

# ---------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  dynamic "configuration" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.kms_key_arn
        logging    = "OVERRIDE"
        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = "/aws/ecs/${local.name}"
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}

# ---------------------------------------------------------------------------
# Capacity Providers
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = compact([
    var.use_fargate ? "FARGATE" : null,
    var.use_fargate_spot ? "FARGATE_SPOT" : null,
  ])

  dynamic "default_capacity_provider_strategy" {
    for_each = var.use_fargate ? [1] : []
    content {
      capacity_provider = var.use_fargate_spot ? "FARGATE_SPOT" : "FARGATE"
      weight            = 1
      base              = 1
    }
  }
}

# ---------------------------------------------------------------------------
# Task Execution Role (one shared for all tasks)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name = "${local.name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Task Definitions
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  for_each = var.task_definitions

  family                   = "${local.name}-${each.key}"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  network_mode             = each.value.network_mode
  requires_compatibilities = each.value.requires_compatibilities
  execution_role_arn       = coalesce(each.value.execution_role_arn, aws_iam_role.execution.arn)
  task_role_arn            = each.value.task_role_arn
  container_definitions    = each.value.container_definitions

  dynamic "volume" {
    for_each = each.value.volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
    }
  }

  dynamic "runtime_platform" {
    for_each = each.value.runtime_platform != null ? [each.value.runtime_platform] : []
    content {
      operating_system_family = runtime_platform.value.operating_system_family
      cpu_architecture        = runtime_platform.value.cpu_architecture
    }
  }

  tags = merge(local.tags, { TaskDefinition = each.key })

  lifecycle {
    # New task revision on every apply — services deploy new revision
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# ECS Services
# ---------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  for_each = var.services

  name                               = "${local.name}-${each.key}"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this[each.value.task_definition_key].arn
  desired_count                      = each.value.desired_count
  launch_type                        = length(each.value.capacity_provider_strategy) == 0 ? each.value.launch_type : null
  platform_version                   = each.value.launch_type == "FARGATE" ? each.value.platform_version : null
  propagate_tags                     = each.value.propagate_tags
  enable_execute_command             = each.value.enable_execute_command
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent         = each.value.deployment_maximum_percent

  network_configuration {
    subnets          = each.value.network_configuration.subnets
    security_groups  = each.value.network_configuration.security_groups
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = each.value.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = service_registries.value.port
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = each.value.deployment_circuit_breaker != null ? [each.value.deployment_circuit_breaker] : []
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = each.value.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  tags = merge(local.tags, { Service = each.key })

  lifecycle {
    # Ignore desired count changes (managed by Application Auto Scaling)
    ignore_changes = [desired_count, task_definition, tags["CreatedDate"]]
  }
}
