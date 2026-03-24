aws_region  = "us-east-1"
name        = "web-server"
environment = "prod"
project     = "platform"
owner       = "infra-team"
cost_center = "CC-100"

instance_type               = "t3.medium"
subnet_id                   = "subnet-0prodprivate1"
key_name                    = "prod-ec2-keypair"
associate_public_ip_address = false
monitoring                  = true
disable_api_termination     = true
