provider "aws" {
  region = var.region
}

module "efs" {
  source = "../../"

  # Identity
  name        = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center
  tags        = var.tags

  # Feature toggles
  create                  = var.create
  create_security_group   = var.create_security_group
  enable_lifecycle_policy = var.enable_lifecycle_policy
  enable_backup_policy    = var.enable_backup_policy
  enable_replication      = var.enable_replication

  # Core
  encrypted                       = var.encrypted
  kms_key_arn                     = var.kms_key_arn
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps

  # Lifecycle
  transition_to_ia                    = var.transition_to_ia
  transition_to_primary_storage_class = var.transition_to_primary_storage_class

  # Network
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  security_group_ids         = var.security_group_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  allowed_security_group_ids = var.allowed_security_group_ids

  # Access points
  access_points = var.access_points

  # Cross-region replication
  replication_destination_region            = var.replication_destination_region
  replication_destination_kms_key_arn       = var.replication_destination_kms_key_arn
  replication_destination_availability_zone = var.replication_destination_availability_zone
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "file_system_id" { value = module.efs.file_system_id }
output "file_system_arn" { value = module.efs.file_system_arn }
output "dns_name" { value = module.efs.dns_name }
output "security_group_id" { value = module.efs.security_group_id }
output "mount_target_ids" { value = module.efs.mount_target_ids }
output "mount_target_dns_names" { value = module.efs.mount_target_dns_names }
output "access_point_ids" { value = module.efs.access_point_ids }
output "access_point_arns" { value = module.efs.access_point_arns }
output "replication_destination_file_system_id" {
  value = module.efs.replication_destination_file_system_id
}

# ---------------------------------------------------------------------------
# Mount command helpers
# ---------------------------------------------------------------------------
output "mount_command_nfs" {
  description = "Example NFS mount command"
  value       = "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${module.efs.dns_name}:/ /mnt/efs"
}

output "mount_command_efs_utils" {
  description = "Example mount command using amazon-efs-utils (recommended)"
  value       = "sudo mount -t efs -o tls ${module.efs.file_system_id}:/ /mnt/efs"
}
