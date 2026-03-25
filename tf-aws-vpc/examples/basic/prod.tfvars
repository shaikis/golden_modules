aws_region           = "us-east-1"
name                 = "my-vpc"
environment          = "prod"
project              = "demo"
owner                = "platform-team"
cost_center          = "CC-100"
cidr_block           = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = false
tags = {
  Environment = "prod"
}
