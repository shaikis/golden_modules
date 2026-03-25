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
