# staging — dedicated VPC, moderate capacity
aws_region  = "us-east-1"
name        = "platform-storage"
environment = "staging"
project     = "platform"
owner       = "storage-team"
cost_center = "CC-400"

windows = {
  storage_capacity                  = 256
  subnet_ids                        = ["subnet-0stg1", "subnet-0stg2"]
  security_group_ids                = ["sg-0fsx-windows-stg"]
  deployment_type                   = "MULTI_AZ_1"
  preferred_subnet_id               = "subnet-0stg1"
  throughput_capacity               = 64
  automatic_backup_retention_days   = 7
  skip_final_backup                 = true
  active_directory_id               = "d-1234567890"
}

ontap = {
  storage_capacity              = 1024
  subnet_ids                    = ["subnet-0stg1", "subnet-0stg2"]
  security_group_ids            = ["sg-0fsx-ontap-stg"]
  deployment_type               = "MULTI_AZ_1"
  preferred_subnet_id           = "subnet-0stg1"
  throughput_capacity           = 128
  automatic_backup_retention_days = 7
  fsx_admin_password            = "CHANGE_ME_STAGING"
  svms = {
    app = {
      name                       = "app-svm"
      root_volume_security_style = "UNIX"
      active_directory = {
        dns_ips     = ["10.0.0.10", "10.0.0.11"]
        domain_name = "corp.internal"
        password    = "CHANGE_ME"
        username    = "svc-fsx"
      }
      volumes = {
        data = {
          name              = "app_data"
          junction_path     = "/app/data"
          size_in_megabytes = 51200
          security_style    = "UNIX"
          tiering_policy    = { name = "AUTO"; cooling_period = 31 }
        }
      }
    }
  }
}

lustre  = null
openzfs = null

enable_ontap_backup              = true
enable_ontap_cross_region_backup = false
