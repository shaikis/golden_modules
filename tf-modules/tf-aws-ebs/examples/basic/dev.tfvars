# dev / staging / qa — same AZ/region
aws_region  = "us-east-1"
name        = "app-data"
environment = "dev"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

volumes = {
  data = {
    availability_zone = "us-east-1a"
    size              = 100
    type              = "gp3"
  }
  logs = {
    availability_zone = "us-east-1a"
    size              = 50
    type              = "gp3"
  }
}

volume_attachments = {
  data_attach = {
    volume_key  = "data"
    instance_id = "i-0devappserver"
    device_name = "/dev/sdf"
  }
}

enable_dlm = true
dlm_target_tags = { Environment = "dev"; Backup = "true" }
dlm_schedules = [
  {
    name         = "daily"
    interval     = 24
    times        = ["03:00"]
    retain_count = 3
    copy_tags    = true
  }
]
