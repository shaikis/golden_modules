output "redis_replication_group_id" { value = length(aws_elasticache_replication_group.this) > 0 ? aws_elasticache_replication_group.this[0].id : null }
output "redis_primary_endpoint_address" { value = length(aws_elasticache_replication_group.this) > 0 ? aws_elasticache_replication_group.this[0].primary_endpoint_address : null }
output "redis_reader_endpoint_address" { value = length(aws_elasticache_replication_group.this) > 0 ? aws_elasticache_replication_group.this[0].reader_endpoint_address : null }
output "redis_configuration_endpoint_address" { value = length(aws_elasticache_replication_group.this) > 0 ? aws_elasticache_replication_group.this[0].configuration_endpoint_address : null }
output "redis_port" { value = var.engine == "redis" ? var.port : null }
output "memcached_cluster_id" { value = length(aws_elasticache_cluster.memcached) > 0 ? aws_elasticache_cluster.memcached[0].id : null }
output "memcached_configuration_endpoint" { value = length(aws_elasticache_cluster.memcached) > 0 ? aws_elasticache_cluster.memcached[0].configuration_endpoint : null }
output "subnet_group_name" { value = length(aws_elasticache_subnet_group.this) > 0 ? aws_elasticache_subnet_group.this[0].name : var.subnet_group_name }
