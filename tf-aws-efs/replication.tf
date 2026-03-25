# ---------------------------------------------------------------------------
# Cross-Region Replication (optional — enable for DR/multi-region workloads)
# NOTE: AWS automatically creates the destination EFS file system.
#       You do NOT need to pre-create it. Disabling this resource will
#       delete the replication but leave the destination FS intact.
# ---------------------------------------------------------------------------
resource "aws_efs_replication_configuration" "this" {
  count = var.create && var.enable_replication ? 1 : 0

  source_file_system_id = aws_efs_file_system.this[0].id

  destination {
    region                 = var.replication_destination_region
    kms_key_id             = var.replication_destination_kms_key_arn
    availability_zone_name = var.replication_destination_availability_zone
  }
}
