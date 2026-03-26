# Amazon DocumentDB Module

A production-ready Terraform module that provisions an **Amazon DocumentDB** (MongoDB-compatible) cluster with TLS enforcement, KMS encryption at rest, multi-AZ instance placement, and automatic master-password generation stored securely in AWS Secrets Manager.

---

## Architecture

```
                          ┌─────────────────────────────────────────────────┐
                          │                    VPC                          │
                          │                                                 │
  ┌─────────────┐         │  ┌──────────────────────────────────────────┐  │
  │ Application │─────────┼─▶│          Security Group (:27017)         │  │
  │  (ECS/EC2)  │  TLS    │  └────────────────┬─────────────────────────┘  │
  └─────────────┘         │                   │                             │
         │                │     ┌─────────────▼──────────────────────┐     │
         │                │     │        DocumentDB Cluster           │     │
         │                │     │    (cluster endpoint / writer)      │     │
         │                │     │                                     │     │
         │                │     │  ┌──────────┐  ┌────────────────┐  │     │
         │                │     │  │  AZ-1    │  │     AZ-2       │  │     │
         │                │     │  │ PRIMARY  │  │    READER      │  │     │
         │                │     │  │(tier 0)  │  │   (tier 1)     │  │     │
         │                │     │  └──────────┘  └────────────────┘  │     │
         │                │     │                                     │     │
         │                │     │              ┌────────────────┐     │     │
         │                │     │              │     AZ-3       │     │     │
         │                │     │              │    READER      │     │     │
         │                │     │              │   (tier 2)     │     │     │
         │                │     │              └────────────────┘     │     │
         │                │     └─────────────────────────────────────┘     │
         │                │                                                 │
         │                └─────────────────────────────────────────────────┘
         │
         │         ┌──────────────────────┐     ┌──────────────────────────┐
         └────────▶│   Secrets Manager    │     │   CloudWatch Logs        │
                   │  (credentials + URI) │     │  /aws/docdb/<name>/audit │
                   │  KMS-encrypted       │     │  /aws/docdb/<name>/       │
                   └──────────────────────┘     │           profiler       │
                                                └──────────────────────────┘

                   ┌──────────────────────┐
                   │   KMS Customer Key   │
                   │  (storage + secrets  │
                   │   + log encryption)  │
                   └──────────────────────┘
```

---

## Features

- **TLS enforced** via a custom DocumentDB cluster parameter group (`tls = enabled`)
- **KMS encryption at rest** — pass your own CMK ARN or rely on the AWS-managed key
- **Multi-AZ** — deploy 1–16 instances spread across your chosen subnets; `promotion_tier` drives automatic failover ordering
- **Automatic password management** — when `master_password` is left `null` a 32-character random password is generated and stored in Secrets Manager alongside the full MongoDB connection URI
- **CloudWatch log export** — audit and/or profiler logs with configurable retention
- **Deletion protection** enabled by default with a configurable final snapshot
- **Horde-compatible URI** — the Secrets Manager secret includes `retryWrites=false` and the RDS CA bundle path required by Amazon DocumentDB

---

## Usage

### Minimal — Horde dev (single instance, no deletion protection)

```hcl
module "documentdb" {
  source = "../../tf-aws-documentdb"

  name        = "horde"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_size        = 1
  instance_class      = "db.t4g.medium"
  skip_final_snapshot = true
  deletion_protection = false

  allowed_security_group_ids = [module.ecs.task_security_group_id]

  tags = {
    Team    = "platform"
    Project = "horde"
  }
}
```

### Production — 3-node cluster with custom KMS key

```hcl
module "documentdb_prod" {
  source = "../../tf-aws-documentdb"

  name        = "horde"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Cluster sizing
  cluster_size   = 3
  instance_class = "db.r6g.xlarge"
  engine_version = "5.0.0"

  # Security
  storage_encrypted = true
  kms_key_id        = module.kms.key_arn
  tls_enabled       = true

  # Access
  allowed_security_group_ids = [
    module.ecs_app.task_security_group_id,
    module.bastion.security_group_id,
  ]

  # Backup & maintenance
  backup_retention_days        = 14
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  skip_final_snapshot          = false
  deletion_protection          = true

  # Logs
  enabled_cloudwatch_logs = ["audit", "profiler"]
  log_retention_days      = 30

  tags = {
    Team        = "platform"
    Project     = "horde"
    CostCenter  = "engineering"
  }
}
```

### Custom parameters (e.g. profiling slow ops > 100 ms)

```hcl
module "documentdb_tuned" {
  source = "../../tf-aws-documentdb"

  name        = "horde"
  environment = "staging"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_size   = 2
  instance_class = "db.r6g.large"

  allowed_security_group_ids = [module.ecs.task_security_group_id]

  enabled_cloudwatch_logs = ["audit", "profiler"]

  cluster_parameters = [
    {
      name         = "profiler"
      value        = "enabled"
      apply_method = "pending-reboot"
    },
    {
      name         = "profiler_threshold_ms"
      value        = "100"
      apply_method = "pending-reboot"
    },
    {
      name         = "change_stream_log_retention_duration"
      value        = "10800"
      apply_method = "pending-reboot"
    },
  ]

  tags = {
    Team = "platform"
  }
}
```

---

## Connecting to DocumentDB

### TLS requirement

Amazon DocumentDB **always** requires the AWS/RDS combined CA bundle when TLS is enabled. Download it once and place it where your application can read it:

```bash
# Download the CA bundle
curl -o /etc/ssl/certs/rds-combined-ca-bundle.pem \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

For container workloads, bake the CA bundle into your Docker image or mount it via a ConfigMap / ECS volume.

### Connection string format

```
mongodb://<username>:<password>@<cluster-endpoint>:27017/?tls=true&tlsCAFile=/etc/ssl/certs/rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

Key parameters explained:

| Parameter | Value | Reason |
|---|---|---|
| `tls` | `true` | Required when `tls_enabled = true` (default) |
| `tlsCAFile` | path to CA bundle | DocumentDB uses an Amazon-issued certificate |
| `replicaSet` | `rs0` | DocumentDB always presents itself as replica set `rs0` |
| `readPreference` | `secondaryPreferred` | Routes reads to reader instances, writes to primary |
| `retryWrites` | `false` | DocumentDB does not support MongoDB retryable writes |

### Retrieving the secret at runtime

```python
import boto3, json

client = boto3.client("secretsmanager", region_name="us-east-1")
secret = json.loads(
    client.get_secret_value(SecretId="horde-prod-docdb-credentials")["SecretString"]
)

uri      = secret["uri"]       # Full MongoDB URI with credentials
username = secret["username"]
password = secret["password"]
host     = secret["host"]
port     = secret["port"]
```

---

## Horde Integration

[Horde](https://docs.unrealengine.com/en-US/horde/) is Epic Games' build/CI backend that uses MongoDB as its datastore. DocumentDB is a drop-in replacement with these requirements:

1. **`retryWrites=false`** — Horde's MongoDB driver sends retryable write commands that DocumentDB does not support. The URI stored in Secrets Manager already includes this flag.
2. **`replicaSet=rs0`** — Horde uses replica-set-aware connection strings. DocumentDB exposes `rs0`.
3. **CA bundle** — Mount `/etc/ssl/certs/rds-combined-ca-bundle.pem` into your Horde container.

Example Horde `server.json` snippet:

```json
{
  "DatabaseConnectionString": "mongodb://docdbadmin:<password>@horde-prod.cluster-xxxx.us-east-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=/etc/ssl/certs/rds-combined-ca-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
  "DatabaseName": "horde"
}
```

The `credentials_secret_arn` output can be passed directly to the Horde ECS task definition as an environment secret so credentials are never stored in plaintext.

---

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `name` | Name of the DocumentDB cluster. | `string` | — | yes |
| `environment` | Deployment environment (dev, staging, prod). | `string` | `"dev"` | no |
| `tags` | Additional tags applied to all resources. | `map(string)` | `{}` | no |
| `vpc_id` | VPC ID where the DocumentDB cluster will be deployed. | `string` | — | yes |
| `subnet_ids` | List of private subnet IDs (minimum 2, in different AZs). | `list(string)` | — | yes |
| `allowed_cidr_blocks` | CIDR blocks allowed to reach port 27017. | `list(string)` | `[]` | no |
| `allowed_security_group_ids` | Security group IDs allowed to reach DocumentDB. | `list(string)` | `[]` | no |
| `engine_version` | DocumentDB engine version. | `string` | `"5.0.0"` | no |
| `instance_class` | Instance class for all cluster members. | `string` | `"db.r6g.large"` | no |
| `cluster_size` | Total number of instances (1–16). First is primary; rest are readers. | `number` | `3` | no |
| `master_username` | Master username. | `string` | `"docdbadmin"` | no |
| `master_password` | Master password. `null` triggers auto-generation. | `string` | `null` | no |
| `port` | DocumentDB listener port. | `number` | `27017` | no |
| `backup_retention_days` | Automated backup retention in days (1–35). | `number` | `7` | no |
| `preferred_backup_window` | Daily backup window (UTC). | `string` | `"03:00-04:00"` | no |
| `preferred_maintenance_window` | Weekly maintenance window (UTC). | `string` | `"sun:05:00-sun:06:00"` | no |
| `skip_final_snapshot` | Skip final snapshot on deletion. | `bool` | `false` | no |
| `final_snapshot_identifier` | Final snapshot name override. | `string` | `null` | no |
| `deletion_protection` | Enable deletion protection. | `bool` | `true` | no |
| `apply_immediately` | Apply modifications immediately instead of next window. | `bool` | `false` | no |
| `storage_encrypted` | Enable storage encryption at rest. | `bool` | `true` | no |
| `kms_key_id` | KMS key ARN for encryption. AWS-managed key used when `null`. | `string` | `null` | no |
| `tls_enabled` | Enforce TLS on all connections. | `bool` | `true` | no |
| `enabled_cloudwatch_logs` | Log types to export (`audit`, `profiler`). | `list(string)` | `["audit"]` | no |
| `log_retention_days` | CloudWatch log retention in days. | `number` | `14` | no |
| `cluster_parameters` | Additional cluster parameter group entries. | `list(object)` | `[]` | no |

---

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | Identifier of the DocumentDB cluster. |
| `cluster_arn` | ARN of the DocumentDB cluster. |
| `cluster_endpoint` | Writer endpoint — use for all write operations. |
| `reader_endpoint` | Reader endpoint — load-balances across reader instances. |
| `port` | DocumentDB listener port. |
| `master_username` | Master username. |
| `credentials_secret_arn` | ARN of the Secrets Manager secret (credentials + URI). |
| `credentials_secret_name` | Name of the Secrets Manager secret. |
| `security_group_id` | ID of the DocumentDB security group. |
| `subnet_group_name` | Name of the DocumentDB subnet group. |
| `instance_ids` | List of all cluster instance identifiers. |
| `cluster_resource_id` | Cluster resource ID (used for IAM auth policies). |
| `connection_string` | MongoDB-compatible connection string (password redacted). |

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3.0 |
| hashicorp/aws | >= 5.0 |

> The `random` provider is also used (no explicit version constraint required beyond Terraform >= 1.3.0).

---

## Notes

- **Subnet group requires at least 2 subnets** in different Availability Zones even for `cluster_size = 1`, because AWS requires it for the subnet group resource.
- **`promotion_tier`** values are set to the instance index (`0`, `1`, `2`, …). Instance `0` is preferred as primary during failover; higher-numbered instances are considered last.
- When `skip_final_snapshot = false` (the default) you must either set `final_snapshot_identifier` or allow the module to derive one as `<name>-<environment>-final-snapshot`. The cluster **cannot be destroyed** while `deletion_protection = true` — disable it first or set it to `false` before running `terraform destroy`.
- **DocumentDB does not support all MongoDB features.** Review the [AWS DocumentDB compatibility guide](https://docs.aws.amazon.com/documentdb/latest/developerguide/mongo-apis.html) before migrating existing workloads.
