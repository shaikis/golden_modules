locals {
  scheduled_action_role_arn = var.create_scheduled_actions ? (
    var.create_iam_role
    ? aws_iam_role.redshift_scheduler[0].arn
    : var.role_arn
  ) : null
}

resource "aws_redshift_scheduled_action" "this" {
  for_each = var.create_scheduled_actions ? var.scheduled_actions : {}

  name        = each.key
  description = each.value.description
  schedule    = each.value.schedule
  iam_role    = coalesce(each.value.iam_role_arn, local.scheduled_action_role_arn)
  start_time  = each.value.start_time
  end_time    = each.value.end_time
  enable      = each.value.enable

  dynamic "target_action" {
    for_each = each.value.action_type == "pause_cluster" ? [1] : []
    content {
      pause_cluster {
        cluster_identifier = (
          each.value.cluster_key != null
          ? aws_redshift_cluster.this[each.value.cluster_key].cluster_identifier
          : each.value.cluster_identifier
        )
      }
    }
  }

  dynamic "target_action" {
    for_each = each.value.action_type == "resume_cluster" ? [1] : []
    content {
      resume_cluster {
        cluster_identifier = (
          each.value.cluster_key != null
          ? aws_redshift_cluster.this[each.value.cluster_key].cluster_identifier
          : each.value.cluster_identifier
        )
      }
    }
  }

  dynamic "target_action" {
    for_each = each.value.action_type == "resize_cluster" ? [1] : []
    content {
      resize_cluster {
        cluster_identifier = (
          each.value.cluster_key != null
          ? aws_redshift_cluster.this[each.value.cluster_key].cluster_identifier
          : each.value.cluster_identifier
        )
        classic         = each.value.classic
        cluster_type    = each.value.cluster_type
        node_type       = each.value.node_type
        number_of_nodes = each.value.number_of_nodes
      }
    }
  }
}
