###############################################################################
# AWS Batch Fair-Share Scheduling Policies
###############################################################################

resource "aws_batch_scheduling_policy" "this" {
  for_each = var.create_scheduling_policies ? var.scheduling_policies : {}

  name = each.key

  fair_share_policy {
    compute_reservation = each.value.compute_reservation
    share_decay_seconds = each.value.share_decay_seconds

    dynamic "share_distribution" {
      for_each = each.value.share_distributions
      content {
        share_identifier = share_distribution.value.share_identifier
        weight_factor    = share_distribution.value.weight_factor
      }
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = each.key
  })
}
