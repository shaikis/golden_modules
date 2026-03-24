aws_region  = "us-east-1"
name        = "app-data"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

volumes = {
  data = {
    availability_zone = "us-east-1a"
    size              = 500
    type              = "io2"
    iops              = 10000
  }
  data_b = {
    availability_zone = "us-east-1b"
    size              = 500
    type              = "io2"
    iops              = 10000
  }
}

volume_attachments = {
  data_attach_a = {
    volume_key  = "data"
    instance_id = "i-0prodserver1"
    device_name = "/dev/sdf"
  }
  data_attach_b = {
    volume_key  = "data_b"
    instance_id = "i-0prodserver2"
    device_name = "/dev/sdf"
  }
}

enable_dlm = true
dlm_target_tags = { Environment = "prod"; Backup = "true" }
dlm_schedules = [
  {
    name         = "daily"
    interval     = 24
    times        = ["02:00"]
    retain_count = 14
    copy_tags    = true
    cross_region_copy_rule = {
      target          = "us-west-2"
      encrypted       = true
      retain_interval = 7
      retain_unit     = "DAYS"
    }
  },
  {
    name         = "hourly"
    interval     = 4
    interval_unit = "HOURS"
    times        = []
    retain_count = 6
    copy_tags    = true
  }
]
