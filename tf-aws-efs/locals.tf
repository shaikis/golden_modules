locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : "${var.project}-${var.environment}-${var.name}"

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-efs"
    },
    var.tags
  )

  legacy_replications = (
    length(var.replications) == 0 && var.enable_replication
    ? {
      default = {
        use_module_source                  = true
        destination_region                 = var.replication_destination_region
        destination_kms_key_arn            = var.replication_destination_kms_key_arn
        destination_availability_zone_name = var.replication_destination_availability_zone
      }
    }
    : {}
  )

  requested_replications = length(var.replications) > 0 ? var.replications : local.legacy_replications

  normalized_replications = {
    for key, replication in local.requested_replications : key => {
      source_file_system_id              = try(replication.use_module_source, false) ? try(aws_efs_file_system.this[0].id, null) : try(replication.source_file_system_id, null)
      destination_file_system_id         = try(replication.destination_file_system_id, null)
      destination_region                 = try(replication.destination_region, null)
      destination_kms_key_arn            = try(replication.destination_kms_key_arn, null)
      destination_availability_zone_name = try(replication.destination_availability_zone_name, null)
      use_module_source                  = try(replication.use_module_source, false)
    }
  }
}
