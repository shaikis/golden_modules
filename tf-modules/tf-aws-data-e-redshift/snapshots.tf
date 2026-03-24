resource "aws_redshift_snapshot_schedule" "this" {
  for_each = var.create_snapshot_schedules ? var.snapshot_schedules : {}

  identifier  = coalesce(each.value.identifier, each.key)
  description = each.value.description
  definitions = each.value.definitions

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.identifier, each.key)
  })
}

# Associate snapshot schedules with clusters
resource "aws_redshift_snapshot_schedule_association" "this" {
  for_each = var.create_snapshot_schedules ? {
    for pair in flatten([
      for sched_key, sched in var.snapshot_schedules : [
        for cluster_key in sched.cluster_keys : {
          sched_key   = sched_key
          cluster_key = cluster_key
        }
      ]
    ]) : "${pair.sched_key}__${pair.cluster_key}" => pair
  } : {}

  cluster_identifier  = aws_redshift_cluster.this[each.value.cluster_key].cluster_identifier
  schedule_identifier = aws_redshift_snapshot_schedule.this[each.value.sched_key].id
}

# Cross-region snapshot copy grants
resource "aws_redshift_snapshot_copy_grant" "this" {
  for_each = var.create_snapshot_schedules ? var.snapshot_copy_grants : {}

  snapshot_copy_grant_name = each.value.snapshot_copy_grant_name
  kms_key_id               = coalesce(each.value.kms_key_id, var.kms_key_arn)

  tags = merge(var.tags, each.value.tags, {
    Name = each.value.snapshot_copy_grant_name
  })
}
