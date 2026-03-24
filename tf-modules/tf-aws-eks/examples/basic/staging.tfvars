aws_region              = "us-east-1"
name                    = "staging-cluster"
environment             = "staging"
subnet_ids              = ["subnet-aaa", "subnet-bbb"]
vpc_id                  = "vpc-0123456789abcdef0"
endpoint_public_access  = false
endpoint_private_access = true
public_access_cidrs     = []
node_groups = {
  general = {
    instance_types = ["t3.large"]
    desired_size   = 3
    min_size       = 2
    max_size       = 6
  }
}
tags = {
  Environment = "staging"
}
