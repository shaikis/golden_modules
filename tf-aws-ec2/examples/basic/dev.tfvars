aws_region  = "us-east-1"
name        = "web-server"
environment = "dev"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

instance_type               = "t3.micro"
subnet_id                   = "subnet-0devprivate1"
key_name                    = null
associate_public_ip_address = false
monitoring                  = false
disable_api_termination     = false
