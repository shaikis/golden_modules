aws_region           = "us-east-1"
name                 = "my-vpc"
environment          = "staging"
project              = "demo"
owner                = "platform-team"
cost_center          = "CC-100"
cidr_block           = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = true
tags = {
  Environment = "staging"
}
