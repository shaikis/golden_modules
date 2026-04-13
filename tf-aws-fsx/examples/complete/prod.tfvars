# prod — dedicated VPC, HA/multi-AZ, larger capacity, all 4 FSx types
aws_region  = "us-east-1"
name        = "platform-storage"
environment = "prod"
project     = "platform"
owner       = "storage-team"
cost_center = "CC-400"

# Windows File Server — enterprise CIFS/SMB, audit logging
windows = {
  storage_capacity                  = 2000
  subnet_ids                        = ["subnet-0prod1", "subnet-0prod2"]
  security_group_ids                = ["sg-0fsx-windows-prod"]
  deployment_type                   = "MULTI_AZ_1"
  preferred_subnet_id               = "subnet-0prod1"
  storage_type                      = "SSD"
  throughput_capacity               = 1024
  automatic_backup_retention_days   = 30
  daily_automatic_backup_start_time = "02:00"
  weekly_maintenance_start_time     = "1:02:00"
  copy_tags_to_backups              = true
  skip_final_backup                 = false
  active_directory_id               = "d-9999999999" # prod AWS Managed AD
  audit_log_destination             = "arn:aws:logs:us-east-1:111122223333:log-group:/aws/fsx/windows"
  file_access_audit_log_level       = "SUCCESS_AND_FAILURE"
}

# Lustre — HPC/ML workloads
lustre = {
  storage_capacity                = 4800
  subnet_ids                      = ["subnet-0prod1"]
  security_group_ids              = ["sg-0fsx-lustre-prod"]
  deployment_type                 = "PERSISTENT_2"
  storage_type                    = "SSD"
  per_unit_storage_throughput     = 500
  data_compression_type           = "LZ4"
  automatic_backup_retention_days = 7
  copy_tags_to_backups            = true
  file_system_type_version        = "2.15"
}

# ONTAP — enterprise NAS with AD join, tiering, multiple SVMs
ontap = {
  storage_capacity                  = 10240
  subnet_ids                        = ["subnet-0prod1", "subnet-0prod2"]
  security_group_ids                = ["sg-0fsx-ontap-prod"]
  deployment_type                   = "MULTI_AZ_1"
  preferred_subnet_id               = "subnet-0prod1"
  throughput_capacity               = 1024
  automatic_backup_retention_days   = 30
  daily_automatic_backup_start_time = "02:00"
  fsx_admin_password_secret_id      = "prod/fsx/admin"
  ha_pairs                          = 1

  svms = {
    app = {
      name                       = "prod-app-svm"
      root_volume_security_style = "UNIX"
      active_directory = {
        dns_ips                                = ["10.10.0.10", "10.10.0.11"]
        domain_name                            = "corp.internal"
        password_secret_id                     = "prod/fsx/domain-join"
        username                               = "svc-fsx-prod"
        organizational_unit_distinguished_name = "OU=FSx,DC=corp,DC=internal"
        netbios_name                           = "PROD-APP-SVM"
      }
      volumes = {
        appdata = {
          name               = "prod_app_data"
          junction_path      = "/prod/data"
          size_in_megabytes  = 512000 # 500 GiB
          security_style     = "UNIX"
          storage_efficiency = true
          tiering_policy = {
            name           = "AUTO"
            cooling_period = 31
          }
          snapshot_policy      = "default"
          copy_tags_to_backups = true
        }
        appshare = {
          name              = "prod_app_share"
          junction_path     = "/prod/share"
          size_in_megabytes = 102400 # 100 GiB
          security_style    = "NTFS" # Windows clients
          tiering_policy    = { name = "SNAPSHOT_ONLY" }
        }
      }
    }
    dba = {
      name                       = "prod-dba-svm"
      root_volume_security_style = "UNIX"
      volumes = {
        dbbackups = {
          name              = "prod_db_backups"
          junction_path     = "/dba/backups"
          size_in_megabytes = 2048000 # 2 TiB
          security_style    = "UNIX"
          tiering_policy    = { name = "ALL" }
        }
      }
    }
  }
}

# AWS Backup for ONTAP — enabled in prod with cross-region DR
# PREREQUISITE: Create the destination vault in us-west-2 before applying:
#   aws backup create-backup-vault --backup-vault-name prod-fsx-dr-vault --region us-west-2
enable_ontap_backup                      = true
ontap_backup_vault_name                  = "prod-fsx-ontap-vault"
ontap_backup_schedule                    = "cron(0 2 * * ? *)" # daily at 02:00 UTC
ontap_backup_retention_days              = 30
enable_ontap_cross_region_backup         = true
ontap_cross_region_backup_vault_arn      = "arn:aws:backup:us-west-2:111122223333:backup-vault:prod-fsx-dr-vault"
ontap_cross_region_backup_kms_key_arn    = null # uses AWS-managed key in DR region
ontap_cross_region_backup_retention_days = 90

# OpenZFS — container/k8s persistent volumes
openzfs = {
  storage_capacity                  = 1024
  subnet_ids                        = ["subnet-0prod1"]
  security_group_ids                = ["sg-0fsx-openzfs-prod"]
  deployment_type                   = "SINGLE_AZ_1"
  throughput_capacity               = 512
  automatic_backup_retention_days   = 14
  root_volume_data_compression_type = "ZSTD"

  volumes = {
    k8s_pv = {
      name                             = "k8s-pv"
      junction_path                    = "/k8s"
      storage_capacity_quota_gib       = 500
      storage_capacity_reservation_gib = 100
      data_compression_type            = "ZSTD"
      nfs_exports = [{
        client_configurations = [
          {
            clients = "10.10.0.0/16"
            options = ["rw", "crossmnt"]
          }
        ]
      }]
    }
  }
}
