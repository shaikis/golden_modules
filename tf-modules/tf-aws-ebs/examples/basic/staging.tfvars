# staging — dedicated subnets, same AZ
aws_region  = "us-east-1"
name        = "app-data"
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

volumes = {
  data = {
    availability_zone = "us-east-1a"
    size              = 200
    type              = "gp3"
  }
  logs = {
    availability_zone = "us-east-1a"
    size              = 100
    type              = "gp3"
  }
}

volume_attachments = {
  data_attach = {
    volume_key  = "data"
    instance_id = "i-0stgappserver"
    device_name = "/dev/sdf"
  }
}

enable_dlm = true
dlm_target_tags = { Environment = "staging"; Backup = "true" }
dlm_schedules = [
  {
    name         = "daily"
    interval     = 24
    times        = ["03:00"]
    retain_count = 7
    copy_tags    = true
  }
]
