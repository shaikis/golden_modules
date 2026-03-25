aws_region                 = "us-east-1"
name                       = "session-cache"
environment                = "staging"
node_type                  = "cache.t3.small"
subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
security_group_ids         = []
automatic_failover_enabled = true
multi_az_enabled           = false
num_cache_clusters         = 2
tags                       = { Environment = "staging" }
