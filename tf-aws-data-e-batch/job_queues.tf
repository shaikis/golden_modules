###############################################################################
# AWS Batch Job Queues
###############################################################################

locals {
  # Build compute environment order lists — if orders not provided, auto-assign 1,2,3,...
  queue_ce_orders = {
    for queue_key, queue in var.job_queues : queue_key => [
      for idx, ce_key in queue.compute_environment_keys : {
        compute_environment = aws_batch_compute_environment.this[ce_key].arn
        order               = queue.compute_environment_orders != null ? queue.compute_environment_orders[idx] : (idx + 1)
      }
    ]
  }
}

resource "aws_batch_job_queue" "this" {
  for_each = var.job_queues

  name     = each.key
  state    = each.value.state
  priority = each.value.priority

  scheduling_policy_arn = (
    var.create_scheduling_policies && each.value.scheduling_policy_key != null
    ? aws_batch_scheduling_policy.this[each.value.scheduling_policy_key].arn
    : null
  )

  dynamic "compute_environment_order" {
    for_each = local.queue_ce_orders[each.key]
    content {
      compute_environment = compute_environment_order.value.compute_environment
      order               = compute_environment_order.value.order
    }
  }

  dynamic "job_state_time_limit_action" {
    for_each = each.value.job_state_time_limit_actions
    content {
      action           = job_state_time_limit_action.value.action
      max_time_seconds = job_state_time_limit_action.value.max_time_seconds
      reason           = job_state_time_limit_action.value.reason
      state            = job_state_time_limit_action.value.state
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })

  depends_on = [
    aws_batch_compute_environment.this
  ]
}
