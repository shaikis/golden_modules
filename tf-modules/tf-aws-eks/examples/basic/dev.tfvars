aws_region              = "us-east-1"
name                    = "dev-cluster"
environment             = "dev"
subnet_ids              = ["subnet-aaa", "subnet-bbb"]
vpc_id                  = "vpc-0123456789abcdef0"
endpoint_public_access  = true
endpoint_private_access = true
public_access_cidrs     = ["10.0.0.0/8"]
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 1
    max_size       = 4
  }
}
tags = {
  Environment = "dev"
}
