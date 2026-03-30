# tf-aws-rds-aurora

Terraform module for AWS Aurora clusters (MySQL and PostgreSQL).

## Features

- Aurora MySQL and Aurora PostgreSQL
- Provisioned instances (any instance class)
- **Aurora Serverless v2** (`db.serverless` + `serverlessv2_scaling_configuration`)
- Aurora Global Database (multi-region)
- Multiple cluster instances via `for_each` (writer + N readers)
- Auto Scaling of read replicas (CPU-based)
- Managed master password via Secrets Manager
- Cluster parameter groups
- Enhanced Monitoring + Performance Insights
- Backtrack (aurora-mysql)
- `prevent_destroy` on cluster and instances
- `ignore_changes = [master_password, global_cluster_identifier]`

## Engine Combinations

| Use Case | engine | engine_version | instance_class |
|----------|--------|---------------|----------------|
| Aurora PostgreSQL 15 | `aurora-postgresql` | `15.4` | `db.t3.medium` |
| Aurora MySQL 8.0 | `aurora-mysql` | `8.0.mysql_aurora.3.04.0` | `db.t3.medium` |
| Aurora Serverless v2 (PG) | `aurora-postgresql` | `15.4` | `db.serverless` |
| Aurora Serverless v2 (MySQL) | `aurora-mysql` | `8.0.mysql_aurora.3.04.0` | `db.serverless` |

## Architecture

```mermaid
graph TB
    App["Application<br/>(ECS / EC2 / Lambda)"]

    subgraph GlobalCluster["Aurora Global Cluster (optional)"]
        subgraph PrimaryRegion["Primary Region"]
            subgraph PrimaryVPC["VPC"]
                subgraph SubnetA["Private Subnet — AZ-a"]
                    Writer["Aurora Writer Instance<br/>(promotion_tier = 0)"]
                end
                subgraph SubnetB["Private Subnet — AZ-b"]
                    Reader1["Aurora Reader Instance<br/>(promotion_tier = 1)"]
                end
                subgraph SubnetC["Private Subnet — AZ-c"]
                    Reader2["Aurora Reader Instance<br/>(promotion_tier = 2)"]
                end
                WriterEP["Cluster Endpoint<br/>(writer)"]
                ReaderEP["Reader Endpoint<br/>(load-balanced reads)"]
                SG["Security Group<br/>port 5432 / 3306"]
                SubnetGroup["DB Subnet Group"]
            end
        end
        subgraph DRRegion["DR Region (Global DB secondary)"]
            DRCluster["Aurora Secondary Cluster<br/>(read-only until failover)"]
        end
    end

    Serverless["Aurora Serverless v2<br/>instance_class = db.serverless<br/>min 0.5 → max 32 ACU"]
    KMS["KMS CMK<br/>(storage + Secrets Manager +<br/>Performance Insights)"]
    ParamGroup["Cluster Parameter Group"]
    Secrets["Secrets Manager<br/>(master password)"]
    Monitoring["Enhanced Monitoring<br/>(IAM Role → CloudWatch)"]
    PI["Performance Insights"]
    Backtrack["Backtrack<br/>(aurora-mysql, rewind to past)"]
    AutoScale["Auto Scaling<br/>(target CPU %)"]

    App -->|"TLS"| SG
    SG --> WriterEP & ReaderEP
    WriterEP --> Writer
    ReaderEP --> Reader1 & Reader2
    Writer <-->|"storage replication"| Reader1 & Reader2
    SubnetGroup --> SubnetA & SubnetB & SubnetC
    Writer -->|"async global replication"| DRCluster
    KMS -->|"encrypts"| Writer
    KMS -->|"encrypts"| Secrets
    ParamGroup --> Writer
    Writer --> Secrets
    Writer --> Monitoring & PI & Backtrack
    AutoScale -->|"adds / removes readers"| Reader1 & Reader2
    Writer -.->|"Serverless v2 option"| Serverless
```

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
# Provisioned Aurora PostgreSQL with 1 writer + 2 readers
module "aurora" {
  source = "git::https://github.com/your-org/tf-modules.git//tf-aws-rds-aurora?ref=v1.0.0"

  name                 = "platform-db"
  engine               = "aurora-postgresql"
  engine_version       = "15.4"
  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]
  kms_key_id           = module.kms.key_arn

  cluster_instances = {
    "1" = { promotion_tier = 0 }  # writer
    "2" = { promotion_tier = 1 }  # reader
    "3" = { promotion_tier = 2 }  # reader
  }

  autoscaling_enabled  = true
  autoscaling_max_capacity = 5
}
```

```hcl
# Aurora Serverless v2
module "aurora_serverless" {
  source = "..."
  name   = "serverless-db"
  engine = "aurora-postgresql"
  engine_version = "15.4"

  serverlessv2_scaling = [{ min_capacity = 0.5; max_capacity = 16 }]
  cluster_instances = { "1" = { instance_class = "db.serverless" } }
  db_subnet_group_name = module.vpc.database_subnet_group_name
}
```

## Examples

- [Basic](examples/basic/)
- [Complete with Global Cluster + Serverless v2](examples/complete/)

