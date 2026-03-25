###############################################################################
# EMR Serverless Applications
###############################################################################

resource "aws_emrserverless_application" "this" {
  for_each = var.create_serverless_applications ? var.serverless_applications : {}

  name          = each.key
  type          = each.value.type
  release_label = each.value.release_label

  maximum_capacity {
    cpu    = each.value.max_cpu
    memory = each.value.max_memory
    disk   = each.value.max_disk
  }

  auto_start_configuration {
    enabled = each.value.auto_start
  }

  auto_stop_configuration {
    enabled              = each.value.auto_stop
    idle_timeout_minutes = each.value.idle_timeout_minutes
  }

  dynamic "network_configuration" {
    for_each = length(each.value.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = each.value.subnet_ids
      security_group_ids = each.value.security_group_ids
    }
  }

  dynamic "image_configuration" {
    for_each = each.value.image_uri != null ? [1] : []
    content {
      image_uri = each.value.image_uri
    }
  }

  dynamic "initial_capacity" {
    for_each = each.value.initial_capacity
    content {
      worker_type = initial_capacity.key

      worker_configuration {
        cpu    = initial_capacity.value.worker_cpu
        memory = initial_capacity.value.worker_memory
        disk   = initial_capacity.value.worker_disk
      }

      initial_capacity_count = initial_capacity.value.worker_count
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}
