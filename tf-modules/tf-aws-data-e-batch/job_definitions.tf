###############################################################################
# AWS Batch Job Definitions
###############################################################################

locals {
  ecs_task_execution_role_arn = var.create_iam_role ? aws_iam_role.ecs_task_execution[0].arn : null
  batch_job_role_arn          = var.create_iam_role ? aws_iam_role.batch_job[0].arn : null

  # Build container_properties JSON for each job definition
  job_container_properties = {
    for k, v in var.job_definitions : k => (
      v.container_properties_override != null
      ? v.container_properties_override
      : jsonencode(merge(
        {
          image            = v.image
          jobRoleArn       = v.job_role_arn != null ? v.job_role_arn : local.batch_job_role_arn
          executionRoleArn = v.execution_role_arn != null ? v.execution_role_arn : local.ecs_task_execution_role_arn
          command          = v.command

          environment = [
            for env_key, env_val in v.environment : {
              name  = env_key
              value = env_val
            }
          ]

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/aws/batch/job"
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = k
            }
          }

          networkConfiguration = {
            assignPublicIp = v.assign_public_ip
          }
        },
        # For Fargate, use resourceRequirements; for EC2, use vcpus/memory at top level
        contains(v.platform_capabilities, "FARGATE") ? {
          resourceRequirements = concat(
            [
              { type = "VCPU", value = tostring(v.vcpus) },
              { type = "MEMORY", value = tostring(v.memory) }
            ],
            v.gpu_count > 0 ? [{ type = "GPU", value = tostring(v.gpu_count) }] : []
          )
          } : {
          vcpus  = v.vcpus
          memory = v.memory
          resourceRequirements = v.gpu_count > 0 ? [
            { type = "GPU", value = tostring(v.gpu_count) }
          ] : []
        }
        )
      )
    )
  }
}

resource "aws_batch_job_definition" "this" {
  for_each = var.job_definitions

  name = each.key
  type = each.value.type

  platform_capabilities = each.value.platform_capabilities
  propagate_tags        = each.value.propagate_tags
  scheduling_priority   = each.value.scheduling_priority

  container_properties = local.job_container_properties[each.key]

  retry_strategy {
    attempts = each.value.retry_attempts
  }

  timeout {
    attempt_duration_seconds = each.value.timeout_seconds
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}
