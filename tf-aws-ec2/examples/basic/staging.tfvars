aws_region  = "us-east-1"
name        = "web-server"
environment = "staging"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

instance_type               = "t3.small"
subnet_id                   = "subnet-0stgprivate1"
key_name                    = null
associate_public_ip_address = false
monitoring                  = true
disable_api_termination     = false
