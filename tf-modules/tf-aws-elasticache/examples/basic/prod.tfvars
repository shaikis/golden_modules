aws_region                 = "us-east-1"
name                       = "session-cache"
environment                = "prod"
node_type                  = "cache.r6g.large"
subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
security_group_ids         = []
automatic_failover_enabled = true
multi_az_enabled           = true
num_cache_clusters         = 3
tags                       = { Environment = "prod" }
