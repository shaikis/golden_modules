provider "aws" { region = var.aws_region }

module "redis" {
  source      = "../../"
  name        = var.name
  environment = var.environment
  node_type   = var.node_type
  subnet_ids  = var.subnet_ids

  # For dev: simpler config
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  num_cache_clusters         = var.num_cache_clusters
}

output "redis_endpoint" { value = module.redis.redis_primary_endpoint_address }
