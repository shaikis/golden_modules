# tf-aws-elasticache

Terraform module for AWS ElastiCache (Redis and Memcached).

## Features

- Redis replication group (cluster mode disabled or enabled)
- Memcached cluster
- Subnet group auto-created from `subnet_ids`
- Custom parameter group support
- Encryption at rest + in transit (TLS) for Redis
- AUTH token support
- Multi-AZ with automatic failover (Redis)
- Snapshot/backup support
- Log delivery (slow-log, engine-log) to CloudWatch or Firehose
- `prevent_destroy` lifecycle guard
- `ignore_changes = [auth_token]` — rotate without Terraform re-apply

## Security Controls

| Control | Default |
|---------|---------|
| Encryption at rest | `true` |
| Encryption in transit | `true` |
| Multi-AZ | `true` |
| Automatic failover | `true` |
| `prevent_destroy` | `true` |

## Usage

```hcl
module "redis" {
  source      = "git::https://github.com/your-org/tf-modules.git//tf-aws-elasticache?ref=v1.0.0"
  name        = "session-store"
  environment = "prod"
  node_type   = "cache.r6g.large"
  subnet_ids  = module.vpc.private_subnet_ids_list
  security_group_ids = [module.redis_sg.security_group_id]
  kms_key_id  = module.kms.key_arn
}
```

## Examples

- [Basic](examples/basic/)
