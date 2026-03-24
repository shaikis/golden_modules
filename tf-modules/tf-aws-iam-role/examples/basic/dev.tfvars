aws_region              = "us-east-1"
name                    = "app-server-dev"
environment             = "dev"
trusted_role_services   = ["ec2.amazonaws.com"]
create_instance_profile = true
managed_policy_arns     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
tags                    = { Environment = "dev" }
