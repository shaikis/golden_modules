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
