# ===========================================================================
# EBS VOLUMES
# ===========================================================================
resource "aws_ebs_volume" "this" {
  for_each = var.volumes

  availability_zone    = each.value.availability_zone
  size                 = each.value.size
  type                 = each.value.type
  iops                 = each.value.iops
  throughput           = each.value.throughput
  multi_attach_enabled = each.value.multi_attach_enabled
  snapshot_id          = each.value.snapshot_id
  encrypted            = true
  kms_key_id           = var.kms_key_arn

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" }, each.value.additional_tags)

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [snapshot_id]
  }
}

# ===========================================================================
# VOLUME ATTACHMENTS
# ===========================================================================
resource "aws_volume_attachment" "this" {
  for_each = var.volume_attachments

  volume_id    = aws_ebs_volume.this[each.value.volume_key].id
  instance_id  = each.value.instance_id
  device_name  = each.value.device_name
  force_detach = each.value.force_detach
  #stop_instance_before_detach  = each.value.stop_instance_before_detach
}

# ===========================================================================
# MANUAL SNAPSHOTS
# ===========================================================================
resource "aws_ebs_snapshot" "permanent" {
  for_each = { for k, v in var.snapshots : k => v if v.permanent }

  volume_id   = each.value.volume_id
  description = coalesce(each.value.description, "${local.name}-${each.key}-snapshot")
  tags        = merge(local.tags, { Name = "${local.name}-${each.key}-snapshot" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_snapshot" "transient" {
  for_each = { for k, v in var.snapshots : k => v if !v.permanent }

  volume_id   = each.value.volume_id
  description = coalesce(each.value.description, "${local.name}-${each.key}-snapshot")
  tags        = merge(local.tags, { Name = "${local.name}-${each.key}-snapshot" })
}

# ===========================================================================
# CROSS-REGION SNAPSHOT COPY
# ===========================================================================
resource "aws_ebs_snapshot_copy" "this" {
  for_each = var.snapshot_copy

  source_snapshot_id = each.value.source_snapshot_id
  source_region      = each.value.source_region
  description        = coalesce(each.value.description, "${local.name}-${each.key}-copy")
  encrypted          = true
  kms_key_id         = coalesce(each.value.kms_key_id, var.kms_key_arn)
  tags               = merge(local.tags, { Name = "${local.name}-${each.key}-copy" })
}

# ===========================================================================
# DLM LIFECYCLE POLICY
# ===========================================================================
resource "aws_iam_role" "dlm" {
  count = var.enable_dlm ? 1 : 0
  name  = "${local.name}-dlm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dlm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "dlm" {
  count      = var.enable_dlm ? 1 : 0
  role       = aws_iam_role.dlm[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDLMServiceRole"
}

resource "aws_dlm_lifecycle_policy" "this" {
  count = var.enable_dlm ? 1 : 0

  description        = "${local.name} - automated EBS snapshot lifecycle"
  execution_role_arn = aws_iam_role.dlm[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = [var.dlm_target_resource_type]

    target_tags = var.dlm_target_tags

    dynamic "schedule" {
      for_each = var.dlm_schedules
      content {
        name      = schedule.value.name
        copy_tags = schedule.value.copy_tags

        create_rule {
          interval      = schedule.value.interval
          interval_unit = schedule.value.interval_unit
          times         = schedule.value.times
        }

        retain_rule {
          count = schedule.value.retain_count
        }

        dynamic "cross_region_copy_rule" {
          for_each = schedule.value.cross_region_copy_rule != null ? [schedule.value.cross_region_copy_rule] : []
          content {
            target    = cross_region_copy_rule.value.target
            encrypted = cross_region_copy_rule.value.encrypted
            retain_rule {
              interval      = cross_region_copy_rule.value.retain_interval
              interval_unit = cross_region_copy_rule.value.retain_unit
            }
          }
        }

        tags_to_add = merge(local.tags, { SnapshotCreator = "DLM" })
      }
    }
  }

  tags = local.tags
}
