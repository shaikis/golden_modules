# dev / staging / qa — shared lower-env VPC subnets
aws_region  = "us-east-1"
name        = "platform-storage"
environment = "dev"
project     = "platform"
owner       = "storage-team"
cost_center = "CC-400"

# Windows File Server — shared CIFS/SMB storage for dev apps
windows = {
  storage_capacity                  = 32          # minimum 32 GiB for SSD
  subnet_ids                        = ["subnet-0dev1", "subnet-0dev2"]
  security_group_ids                = ["sg-0fsx-windows"]
  deployment_type                   = "MULTI_AZ_1"
  preferred_subnet_id               = "subnet-0dev1"
  throughput_capacity               = 32
  automatic_backup_retention_days   = 3
  skip_final_backup                 = true
  active_directory_id               = "d-1234567890"   # AWS Managed AD
}

# ONTAP — for dev/staging app data
ontap = {
  storage_capacity              = 1024
  subnet_ids                    = ["subnet-0dev1", "subnet-0dev2"]
  security_group_ids            = ["sg-0fsx-ontap"]
  deployment_type               = "MULTI_AZ_1"
  preferred_subnet_id           = "subnet-0dev1"
  throughput_capacity           = 128
  automatic_backup_retention_days = 3
  fsx_admin_password_secret_id  = "dev/fsx/admin"

  svms = {
    app = {
      name                       = "app-svm"
      root_volume_security_style = "UNIX"
      active_directory = {
        dns_ips     = ["10.0.0.10", "10.0.0.11"]
        domain_name = "corp.internal"
        password_secret_id = "dev/fsx/domain-join"
        username    = "svc-fsx"
      }
      volumes = {
        data = {
          name              = "app_data"
          junction_path     = "/app/data"
          size_in_megabytes = 51200   # 50 GiB
          security_style    = "UNIX"
          tiering_policy    = { name = "AUTO"; cooling_period = 31 }
        }
        logs = {
          name              = "app_logs"
          junction_path     = "/app/logs"
          size_in_megabytes = 10240   # 10 GiB
          security_style    = "UNIX"
          tiering_policy    = { name = "ALL" }
        }
      }
    }
  }
}

lustre  = null
openzfs = null

# AWS Backup — disabled in dev (no cross-region needed)
enable_ontap_backup              = false
enable_ontap_cross_region_backup = false
