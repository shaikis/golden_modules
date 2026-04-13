# ---------------------------------------------------------------------------
# Replication configurations
# NOTE: AWS creates the destination EFS automatically when file_system_id is
#       omitted. Existing destination support is modeled through file_system_id.
#       Removing a replication configuration stops replication but does not
#       delete an already-created destination file system.
# ---------------------------------------------------------------------------
resource "aws_efs_replication_configuration" "this" {
  for_each = local.normalized_replications

  source_file_system_id = each.value.source_file_system_id

  destination {
    file_system_id         = each.value.destination_file_system_id
    region                 = each.value.destination_region
    kms_key_id             = each.value.destination_kms_key_arn
    availability_zone_name = each.value.destination_availability_zone_name
  }

  lifecycle {
    precondition {
      condition     = each.value.source_file_system_id != null
      error_message = "Replication source_file_system_id resolved to null. If use_module_source = true, the module-managed file system must be created."
    }
  }
}
