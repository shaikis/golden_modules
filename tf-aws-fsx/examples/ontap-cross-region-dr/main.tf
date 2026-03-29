# =============================================================================
# EXAMPLE: FSx ONTAP — Cross-Region DR (All Three Approaches)
#
# Approach 1: AWS Backup cross-region copy (RPO = hours, no extra provider)
# Approach 2: SnapMirror Async via NetApp ONTAP provider (RPO = ~hourly)
# Approach 3: SVM DR via SnapMirror (replicates entire SVM config + data)
#
# Architecture:
#   Primary region (us-east-1): FSx ONTAP MULTI_AZ_1 + 2 SVMs + volumes
#   DR region     (us-west-2): FSx ONTAP MULTI_AZ_1 (standby, read-only)
#   SnapMirror:   ONTAP-native async replication, hourly schedule
#   AWS Backup:   Daily backup with 30-day retention, copied to DR region
#   Route 53:     Latency-based records + health checks for automatic DNS failover
#
# FAILOVER RUNBOOK (automated with Route 53 ARC):
#   1. Break SnapMirror on destination:
#        snapmirror break -destination-path <dst-svm>:<dst-vol>
#   2. Route 53 health check fails on primary → DNS flips to DR endpoint
#   3. Applications reconnect to DR FSx ONTAP NFS/SMB endpoints
#   4. After primary recovery, resync (reverse mirror) to restore replication
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    netapp-ontap = {
      source  = "NetApp/netapp-ontap"
      version = ">= 1.1"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# ── KMS keys ──────────────────────────────────────────────────────────────────
module "kms_primary" {
  source      = "../../../tf-aws-kms"
  providers   = { aws = aws.primary }
  name_prefix = "${var.name}-primary"
  tags = {
    Environment = var.environment
  }

  keys = {
    fsx = {
      description = "Primary-region KMS key for ${var.name} FSx"
    }
  }
}

module "kms_dr" {
  source      = "../../../tf-aws-kms"
  providers   = { aws = aws.dr }
  name_prefix = "${var.name}-dr"
  tags = {
    Environment = var.environment
  }

  keys = {
    fsx = {
      description = "DR-region KMS key for ${var.name} FSx"
    }
  }
}

# ── Primary FSx ONTAP (us-east-1) ─────────────────────────────────────────────
module "fsx_primary" {
  source    = "../../"
  providers = { aws = aws.primary }

  name        = "${var.name}-primary"
  environment = var.environment
  kms_key_arn = module.kms_primary.key_arns["fsx"]

  ontap = {
    storage_capacity              = var.storage_capacity_gb
    subnet_ids                    = var.primary_subnet_ids
    security_group_ids            = var.primary_security_group_ids
    deployment_type               = "MULTI_AZ_1"
    preferred_subnet_id           = var.primary_subnet_ids[0]
    throughput_capacity           = var.throughput_capacity_mbs
    ha_pairs                      = 1
    fsx_admin_password_secret_id  = var.fsx_admin_password_secret_id
    fsx_admin_password_secret_key = var.fsx_admin_password_secret_key

    svms = {
      app = {
        name                          = "app-svm"
        root_volume_security_style    = "UNIX"
        svm_admin_password_secret_id  = var.svm_admin_password_secret_id
        svm_admin_password_secret_key = var.svm_admin_password_secret_key

        volumes = {
          data = {
            name               = "data"
            junction_path      = "/data"
            size_in_megabytes  = var.data_volume_size_gb * 1024
            security_style     = "UNIX"
            storage_efficiency = true
            tiering_policy     = { name = "AUTO", cooling_period = 31 }
            snapshot_policy    = "default"
          }
          logs = {
            name               = "logs"
            junction_path      = "/logs"
            size_in_megabytes  = var.logs_volume_size_gb * 1024
            security_style     = "UNIX"
            storage_efficiency = true
            tiering_policy     = { name = "SNAPSHOT_ONLY" }
            snapshot_policy    = "default"
          }
        }
      }
    }
  }

  # ── Approach 1: AWS Backup daily backup + cross-region copy ─────────────────
  enable_ontap_backup                      = true
  ontap_backup_schedule                    = "cron(0 2 * * ? *)" # daily 02:00 UTC
  ontap_backup_retention_days              = 30
  enable_ontap_cross_region_backup         = true
  ontap_cross_region_backup_vault_arn      = module.fsx_dr.ontap_backup_vault_arn
  ontap_cross_region_backup_retention_days = 30

  # ── Approach 2+3: SnapMirror Async via NetApp ONTAP provider ─────────────────
  # Phase 1: leave primary/dr management IPs empty → SnapMirror is skipped.
  # Phase 2: fill in both IPs → run `terraform apply` again to create relationships.
  enable_ontap_snapmirror = var.primary_ontap_management_ip != "" && var.dr_ontap_management_ip != ""
  ontap_snapmirror = var.primary_ontap_management_ip != "" && var.dr_ontap_management_ip != "" ? {
    source_management_ip                  = var.primary_ontap_management_ip
    source_admin_password_secret_id       = var.fsx_admin_password_secret_id
    source_admin_password_secret_key      = var.fsx_admin_password_secret_key
    destination_management_ip             = var.dr_ontap_management_ip
    destination_admin_password_secret_id  = var.fsx_admin_password_secret_id
    destination_admin_password_secret_key = var.fsx_admin_password_secret_key

    replication_mode = "async"
    schedule         = "hourly" # snapshot-based async, ~1 hour RPO

    # Approach 2: volume-level SnapMirror (granular)
    volume_relationships = {
      data = {
        source_svm_key          = "app"
        source_volume_key       = "data"
        destination_svm_name    = "app-svm-dr"
        destination_volume_name = "data"
        policy_type             = "MirrorAllSnapshots"
        throttle_kb_s           = 0 # unlimited bandwidth
      }
      logs = {
        source_svm_key          = "app"
        source_volume_key       = "logs"
        destination_svm_name    = "app-svm-dr"
        destination_volume_name = "logs"
        policy_type             = "MirrorAllSnapshots"
        throttle_kb_s           = 10240 # 10 MB/s throttle for logs
      }
    }

    # Approach 3: SVM DR (replicates entire SVM including CIFS/NFS config)
    svm_dr_relationships = {
      app = {
        source_svm_key       = "app"
        destination_svm_name = "app-svm-dr"
      }
    }
  } : null
}

# ── DR FSx ONTAP (us-west-2) ──────────────────────────────────────────────────
module "fsx_dr" {
  source    = "../../"
  providers = { aws = aws.dr }

  name        = "${var.name}-dr"
  environment = var.environment
  kms_key_arn = module.kms_dr.key_arns["fsx"]

  ontap = {
    storage_capacity              = var.storage_capacity_gb
    subnet_ids                    = var.dr_subnet_ids
    security_group_ids            = var.dr_security_group_ids
    deployment_type               = "MULTI_AZ_1"
    preferred_subnet_id           = var.dr_subnet_ids[0]
    throughput_capacity           = var.throughput_capacity_mbs
    ha_pairs                      = 1
    fsx_admin_password_secret_id  = var.fsx_admin_password_secret_id
    fsx_admin_password_secret_key = var.fsx_admin_password_secret_key

    # DR cluster: SVMs are provisioned empty; SnapMirror will populate them
    svms = {
      app-dr = {
        name                          = "app-svm-dr"
        root_volume_security_style    = "UNIX"
        svm_admin_password_secret_id  = var.svm_admin_password_secret_id
        svm_admin_password_secret_key = var.svm_admin_password_secret_key
        volumes                       = {} # volumes created as DP by SnapMirror
      }
    }
  }

  # AWS Backup vault in DR region (receives cross-region copies)
  enable_ontap_backup         = true
  ontap_backup_vault_name     = "${var.name}-dr-vault"
  ontap_backup_schedule       = "cron(0 3 * * ? *)" # offset from primary
  ontap_backup_retention_days = 30
}

# ── Route 53 health checks + failover DNS records ─────────────────────────────
resource "aws_route53_health_check" "primary_nfs" {
  provider          = aws.primary
  fqdn              = module.fsx_primary.ontap_fs_endpoints[0].nfs[0].dns_name
  port              = 2049
  type              = "TCP"
  request_interval  = 10
  failure_threshold = 2
  tags              = { Name = "${var.name}-primary-nfs" }
}

resource "aws_route53_record" "nfs_primary" {
  provider = aws.primary
  zone_id  = var.route53_zone_id
  name     = "nfs.${var.domain}"
  type     = "CNAME"
  ttl      = 30

  failover_routing_policy { type = "PRIMARY" }
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary_nfs.id
  records         = [module.fsx_primary.ontap_fs_endpoints[0].nfs[0].dns_name]
}

resource "aws_route53_record" "nfs_dr" {
  provider = aws.primary
  zone_id  = var.route53_zone_id
  name     = "nfs.${var.domain}"
  type     = "CNAME"
  ttl      = 30

  failover_routing_policy { type = "SECONDARY" }
  set_identifier = "dr"
  records        = [module.fsx_dr.ontap_fs_endpoints[0].nfs[0].dns_name]
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "primary_fs_id" { value = module.fsx_primary.ontap_fs_id }
output "dr_fs_id" { value = module.fsx_dr.ontap_fs_id }
output "nfs_endpoint" { value = "nfs.${var.domain}" }
output "primary_nfs_direct" { value = module.fsx_primary.ontap_fs_endpoints[0].nfs[0].dns_name }
output "dr_nfs_direct" { value = module.fsx_dr.ontap_fs_endpoints[0].nfs[0].dns_name }
output "snapmirror_volumes" { value = module.fsx_primary.ontap_snapmirror_volume_relationship_ids }
output "snapmirror_svm_dr" { value = module.fsx_primary.ontap_snapmirror_svm_dr_relationship_ids }
output "cluster_peer_id" { value = module.fsx_primary.ontap_cluster_peer_id }
output "replication_summary" { value = module.fsx_primary.ontap_replication_summary }
