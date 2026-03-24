aws_region                 = "us-east-1"
name                       = "session-cache"
environment                = "dev"
node_type                  = "cache.t3.micro"
subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
security_group_ids         = []
automatic_failover_enabled = false
multi_az_enabled           = false
num_cache_clusters         = 1
tags                       = { Environment = "dev" }
