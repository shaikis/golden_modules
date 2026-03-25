# Integration test — tf-aws-elasticache basic
# command = apply (creates real AWS resources — costs money)
# Prerequisites: AWS credentials, a VPC with private subnets and a cache subnet group

provider "aws" {
  region = "us-east-1"
}

variables {
  name                     = "tftest-redis"
  engine                   = "redis"
  engine_version           = "7.0"
  node_type                = "cache.t3.micro"
  num_cache_clusters       = 1
  automatic_failover_enabled = false
  multi_az_enabled         = false
  subnet_group_name        = "default"
  apply_immediately        = true
  snapshot_retention_limit = 0
}

# SKIP_IN_CI
run "basic_redis_cluster" {
  command = apply

  module {
    source = "../../"
  }

  assert {
    condition     = output.replication_group_id != ""
    error_message = "Replication group ID should not be empty after apply."
  }

  assert {
    condition     = output.primary_endpoint_address != ""
    error_message = "Primary endpoint should not be empty after apply."
  }
}
