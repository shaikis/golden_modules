aws_region              = "us-east-1"
name                    = "prod-cluster"
environment             = "prod"
subnet_ids              = ["subnet-aaa", "subnet-bbb"]
vpc_id                  = "vpc-0123456789abcdef0"
endpoint_public_access  = false
endpoint_private_access = true
public_access_cidrs     = []
node_groups = {
  general = {
    instance_types = ["m5.large"]
    desired_size   = 4
    min_size       = 3
    max_size       = 10
  }
  spot = {
    instance_types = ["m5.large", "m5a.large", "m4.large"]
    capacity_type  = "SPOT"
    desired_size   = 2
    min_size       = 0
    max_size       = 10
  }
}
tags = {
  Environment = "prod"
}
