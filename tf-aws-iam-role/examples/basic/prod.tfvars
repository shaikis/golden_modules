aws_region              = "us-east-1"
name                    = "app-server-prod"
environment             = "prod"
trusted_role_services   = ["ec2.amazonaws.com"]
create_instance_profile = true
managed_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
]
tags = { Environment = "prod" }
