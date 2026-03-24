# tf-aws-rds

Terraform module for AWS RDS instances and Aurora clusters.
All features are **choice-based** — enable only what you need via `tfvars`.

---

## Supported Database Engines

| Engine | Type | Cross-Region Replica | Backup Replication | Example Folder |
|--------|------|---------------------|-------------------|----------------|
| MySQL 8.0 | RDS | ✅ Yes | ✅ Yes | `cross_region_mysql/` |
| PostgreSQL 16 | RDS | ✅ Yes | ✅ Yes | `cross_region_postgres/` |
| MariaDB 10.11 | RDS | ✅ Yes | ✅ Yes | `cross_region_mariadb/` |
| Oracle EE / SE2 | RDS | ✅ Yes | ✅ Yes | `cross_region_oracle/` |
| SQL Server EE/SE/EX/Web | RDS | ❌ No | ✅ Yes | `cross_region_sqlserver/` |
| Aurora MySQL 3.x (MySQL 8.0) | Aurora | Global DB | N/A | `cross_region_aurora_mysql/` |
| Aurora PostgreSQL 16.x | Aurora | Global DB | N/A | `cross_region_aurora_postgres/` |

---

## Quick Start

```bash
# Choose your engine folder
cd examples/cross_region_mysql

# Initialize Terraform
terraform init

# Plan with environment-specific values
terraform plan -var-file="dev.tfvars"

# Apply
terraform apply -var-file="dev.tfvars"
```

---

## Environment Strategy

| Environment | VPC | Multi-AZ | Cross-Region | Notes |
|------------|-----|---------|-------------|-------|
| dev | Shared (same as staging) | No | Disabled | Cost-optimized |
| staging | Shared (same as dev) | No | Backup only | Pre-prod validation |
| prod | Dedicated | Yes | Backup + Replica | Full HA + DR |

---

## Feature Toggles (Choice-Based)

Every feature is disabled by default. Enable what you need in `tfvars`:

```hcl
# Standard RDS — cross-region options
enable_automated_backup_replication = true   # copy backups to DR region
create_cross_region_replica         = true   # live read replica in DR

# Aurora — global database secondary
create_secondary_region = true

# Backup
backup_retention_period = 7               # 0 = disabled, 1–35 days

# Monitoring
monitoring_interval          = 60         # 0=off, 1,5,10,15,30,60 seconds
performance_insights_enabled = true

# Parameter group
create_parameter_group = true
parameters = [{ name = "...", value = "...", apply_method = "immediate" }]

# Protection
deletion_protection = true
skip_final_snapshot = false
```

---

## Attaching Multiple Security Groups

Pass a **list** to `vpc_security_group_ids`:

```hcl
# tfvars — add as many SGs as needed
primary_security_group_ids = [
  "sg-0appdb1111",      # application tier access (port 3306/5432/1433/1521)
  "sg-0monitoring2222", # CloudWatch/Datadog/Dynatrace agents
  "sg-0admin3333",      # DBA bastion host access
  "sg-0lambda4444",     # AWS Lambda function access
]
```

> **Cross-Region Rule:** Security groups are **VPC-specific**.
> You **cannot reuse** primary-region SG IDs in a DR region.
> Create equivalent SGs in the DR VPC and pass them to `dr_security_group_ids`.

```hcl
# Primary SGs (us-east-1 VPC)
primary_security_group_ids = ["sg-0prodapp1111", "sg-0prodmon2222"]

# DR SGs (us-west-2 VPC) — DIFFERENT IDs, same purpose
dr_security_group_ids = ["sg-0drapp4444", "sg-0drmon5555"]
```

---

## Naming Standards

| Resource | Naming Pattern | Example |
|----------|---------------|---------|
| DB Identifier | `{project}-{env}-{name}` | `myapp-prod-db` |
| Parameter Group | `{project}-{env}-{name}-pg` | `myapp-prod-db-pg` |
| Final Snapshot | `{prefix}-{identifier}` | `prod-final-myapp-prod-db` |
| Monitoring Role | `{project}-{env}-{name}-rds-monitoring` | `myapp-prod-db-rds-monitoring` |
| Replica | `{name}-replica` | `myapp-prod-db-replica` |
| Aurora Cluster | `{project}-{env}-{name}-primary` | `myapp-prod-aurora-primary` |
| Aurora Instance | `{project}-{env}-{name}-primary-{N}` | `myapp-prod-aurora-primary-1` |
| Aurora Global | `{project}-{env}-{name}-global` | `myapp-prod-aurora-global` |

---

## Backups

### Automated Backups Configuration

```hcl
backup_retention_period  = 7        # 0–35 days; 0 disables automated backups
backup_window            = "02:00-03:00"   # UTC; must not overlap maintenance_window
copy_tags_to_snapshot    = true
delete_automated_backups = false    # keep backups on instance deletion
```

> Requirement for backup replication: `backup_retention_period >= 1`

### Cross-Region Backup Replication (Standard RDS)

Copies automated backups to a secondary region for compliance and PITR recovery.

```hcl
enable_automated_backup_replication             = true
automated_backup_replication_retention_period   = 14   # days in DR region
automated_backup_replication_kms_key_arn        = "arn:aws:kms:us-west-2:..."
```

Resource `aws_db_instance_automated_backups_replication` is created in the **DR region**.
Supported: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server.

### Manual Snapshots

```hcl
skip_final_snapshot              = false              # create final snapshot on destroy
final_snapshot_identifier_prefix = "prod-mysql-final"
```

```bash
# Create manual snapshot anytime
aws rds create-db-snapshot \
  --db-instance-identifier myapp-prod-db \
  --db-snapshot-identifier myapp-prod-db-manual-20260322
```

---

## Monitoring

### Enhanced Monitoring (OS-level metrics every N seconds)

```hcl
monitoring_interval    = 60         # 0=disabled, valid: 1,5,10,15,30,60
create_monitoring_role = true       # auto-creates IAM role
# Or bring your own: monitoring_role_arn = "arn:aws:iam::..."
```

### Performance Insights (query-level analysis)

```hcl
performance_insights_enabled          = true
performance_insights_retention_period = 7     # 7 days (free tier) or 731 days
performance_insights_kms_key_id       = null  # null = AWS-managed key
```

### CloudWatch Log Exports

```hcl
enabled_cloudwatch_logs_exports = ["error", "slowquery"]   # MySQL example
```

| Engine | Available Log Types |
|--------|-------------------|
| MySQL | `error`, `general`, `slowquery`, `audit` |
| PostgreSQL | `postgresql`, `upgrade` |
| MariaDB | `error`, `general`, `slowquery` |
| Oracle | `alert`, `audit`, `listener`, `trace` |
| SQL Server | `agent`, `error` |
| Aurora MySQL | `audit`, `error`, `general`, `slowquery` |
| Aurora PostgreSQL | `postgresql` |

---

## Restore and Recovery

### Point-in-Time Recovery (PITR)

Restore to any second within the `backup_retention_period` window.

```bash
# Restore to specific time (UTC)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier myapp-prod-db \
  --target-db-instance-identifier myapp-prod-db-restored-20260322 \
  --restore-time 2026-03-22T02:00:00Z \
  --db-subnet-group-name prod-rds-subnet-group \
  --vpc-security-group-ids sg-0proddb1234 sg-0prodmon5678

# Check restore status
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-db-restored-20260322 \
  --query 'DBInstances[0].DBInstanceStatus'
```

### Restore from Snapshot

```bash
# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier myapp-prod-db \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
  --output table

# Restore snapshot to new instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier myapp-prod-db-restored \
  --db-snapshot-identifier myapp-prod-db-manual-20260322 \
  --db-subnet-group-name prod-rds-subnet-group \
  --vpc-security-group-ids sg-0proddb1234

# Restore cross-region snapshot copy
aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:us-east-1:123456789012:snapshot:myapp-prod-final \
  --target-db-snapshot-identifier myapp-prod-final-dr \
  --kms-key-id arn:aws:kms:us-west-2:... \
  --region us-west-2
```

### Aurora Global Database Failover

```bash
# Managed failover — promotes secondary to primary (~1 minute RTO)
aws rds failover-global-cluster \
  --global-cluster-identifier myapp-prod-aurora-global \
  --target-db-cluster-identifier myapp-prod-aurora-secondary

# Monitor failover status
aws rds describe-global-clusters \
  --global-cluster-identifier myapp-prod-aurora-global \
  --query 'GlobalClusters[0].GlobalClusterMembers[*].[DBClusterArn,IsWriter]'
```

### Promote Read Replica to Standalone (Standard RDS)

```bash
# Promote replica — becomes independent writable instance
aws rds promote-read-replica \
  --db-instance-identifier myapp-prod-db-replica

# Replica is now standalone; update application connection string
```

---

## Parameter Groups

### Overview

Parameter groups control database engine settings. Create a custom group when you need
non-default values. The module creates it automatically when `create_parameter_group = true`.

### Parameter Group Family Reference

| Engine | Version | Family |
|--------|---------|--------|
| MySQL | 8.0.x | `mysql8.0` |
| PostgreSQL | 16.x | `postgres16` |
| PostgreSQL | 15.x | `postgres15` |
| MariaDB | 10.11 | `mariadb10.11` |
| MariaDB | 10.6 | `mariadb10.6` |
| Oracle EE | 19 | `oracle-ee-19` |
| Oracle SE2 | 19 | `oracle-se2-19` |
| SQL Server SE | 15.0 | `sqlserver-se-15.0` |
| SQL Server EE | 15.0 | `sqlserver-ee-15.0` |
| SQL Server EX | 15.0 | `sqlserver-ex-15.0` |
| SQL Server Web | 15.0 | `sqlserver-web-15.0` |
| Aurora MySQL 3.x | 8.0 | `aurora-mysql8.0` |
| Aurora PostgreSQL | 16.x | `aurora-postgresql16` |

### Example Configuration

```hcl
create_parameter_group = true
parameter_group_family = "mysql8.0"

parameters = [
  {
    name         = "max_connections"
    value        = "1000"
    apply_method = "immediate"
  },
  {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "immediate"
  },
  {
    name         = "long_query_time"
    value        = "2"
    apply_method = "immediate"
  },
  {
    name         = "innodb_buffer_pool_size"
    value        = "{DBInstanceClassMemory*3/4}"
    apply_method = "pending-reboot"   # needs restart
  },
]
```

`apply_method`:
- `immediate` — apply without restart (dynamic parameters)
- `pending-reboot` — apply on next maintenance window or manual restart

---

## Option Groups (Oracle and SQL Server)

Option groups add features to Oracle and SQL Server engines.
Use `option_group_name` variable to attach a pre-created option group.

```hcl
option_group_name = "myapp-prod-sqlserver-og"
```

### Naming Standard

```
{project}-{env}-{engine-short}-og
Examples:
  myapp-prod-sqlserver-og
  myapp-prod-oracle-og
```

### Common Options

| Engine | Option | Purpose |
|--------|--------|---------|
| SQL Server | `SQLSERVER_BACKUP_RESTORE` | Native backup/restore to S3 |
| SQL Server | `TDE` | Transparent Data Encryption |
| Oracle | `OEM` | Oracle Enterprise Manager |
| Oracle | `STATSPACK` | Performance statistics |
| Oracle | `S3_INTEGRATION` | Oracle to S3 data transfer |
| Oracle | `Timezone` | Custom timezone files |

### Create Option Group (outside module, one-time)

```bash
# SQL Server option group with backup to S3
aws rds create-option-group \
  --option-group-name myapp-prod-sqlserver-og \
  --engine-name sqlserver-se \
  --major-engine-version "15.00" \
  --option-group-description "SQL Server SE options"

# Add BACKUP_RESTORE option
aws rds add-option-to-option-group \
  --option-group-name myapp-prod-sqlserver-og \
  --options OptionName=SQLSERVER_BACKUP_RESTORE,OptionSettings=[{Name=IAM_ROLE_ARN,Value=arn:aws:iam::...}]
```

---

## Domain Joining

### SQL Server — Active Directory (Windows Authentication)

```bash
# Prerequisites
# 1. AWS Managed AD or AD Connector in same VPC
# 2. Security group rules: RDS → AD ports (88, 389, 445, 636, 1024-65535)
# 3. IAM role with AmazonRDSDirectoryServiceAccess policy
```

Add to `main.tf` module call in the example:
```hcl
module "rds_primary" {
  ...
  domain               = "d-1234567890"              # AWS Managed AD directory ID
  domain_iam_role_name = "myapp-rds-domain-role"     # IAM role for AD join
}
```

### Oracle — Kerberos Authentication

```hcl
module "rds_primary" {
  ...
  domain = "d-1234567890"   # AWS Managed AD directory ID
}
```

---

## Engine-Specific Notes

### MySQL
- Port: `3306` | Replica: ✅ | Backup replication: ✅
- `character_set_name` not supported (use parameter group `character_set_server`)

### PostgreSQL
- Port: `5432` | Replica: ✅ | Backup replication: ✅
- Logical replication: set `rds.logical_replication = 1` in parameter group

### MariaDB
- Port: `3306` | Replica: ✅ | Backup replication: ✅
- Performance Insights: not supported

### Oracle
- Port: `1521` | Replica: ✅ (EE/SE2) | Backup replication: ✅
- `db_name = null` at creation — databases added post-provisioning via SQL
- `character_set_name`: **set once at creation, cannot change** → use `AL32UTF8`
- License: `bring-your-own-license` (BYOL) or `license-included` (LI)

### SQL Server
- Port: `1433` | Replica: ❌ | Backup replication: ✅
- `db_name = null` — databases created after instance is ready
- `timezone` settable at creation (e.g. `"Eastern Standard Time"`)
- Min storage: 200 GiB for SE/EE
- Min instance class: `db.m5.xlarge` for SE; `db.t3.medium` for EX/Web
- For DR: use `enable_automated_backup_replication + multi_az`

### Aurora MySQL
- Engine: `aurora-mysql` | Version format: `8.0.mysql_aurora.3.x.x`
- Cross-region: **Global Database** only (not standard replica)
- Endpoints: writer endpoint + reader endpoint per cluster
- Scale readers: increase `primary_instance_count`

### Aurora PostgreSQL
- Engine: `aurora-postgresql` | Version: `16.2`, `15.x`, etc.
- Cross-region: **Global Database** only
- Compatible with standard PostgreSQL clients and tools

---

## Cross-Region DR Decision Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| Compliance backup in DR region | `enable_automated_backup_replication = true` |
| Fast failover (RTO < 5 min) | `create_cross_region_replica = true` |
| Fastest failover (~1 min), high throughput | Aurora Global Database |
| SQL Server DR | Backup replication + Multi-AZ |
| Oracle DR | Cross-region replica + backup replication |
| Cost-sensitive staging | Backup replication only |
| Production full HA + DR | Multi-AZ + replica/Global DB |

---

## Module Outputs

| Output | Description |
|--------|-------------|
| `db_instance_id` | DB instance identifier |
| `db_instance_arn` | DB instance ARN (needed for backup replication) |
| `db_instance_endpoint` | Connection endpoint (host:port) |
| `db_instance_address` | Hostname only |
| `db_instance_port` | Port number |
| `db_master_user_secret_arn` | Secrets Manager ARN for master password |
| `db_parameter_group_id` | Parameter group name |
| `enhanced_monitoring_iam_role_arn` | Enhanced monitoring role ARN |

---

## Examples Directory

```
examples/
  basic/                        — Single-region RDS (any engine, dev-focused)
  complete/                     — Full-featured single-region
  complete-all-engines/         — All engines comparison
  cross_region/                 — Generic cross-region template
  cross_region_mysql/           — MySQL cross-region
  cross_region_postgres/        — PostgreSQL cross-region
  cross_region_mariadb/         — MariaDB cross-region
  cross_region_oracle/          — Oracle EE/SE2 cross-region
  cross_region_sqlserver/       — SQL Server SE/EE (backup replication only)
  cross_region_aurora_mysql/    — Aurora MySQL Global Database
  cross_region_aurora_postgres/ — Aurora PostgreSQL Global Database
```

Each example folder contains:
- `main.tf` — module call with engine-specific configuration
- `variables.tf` — all input variables with engine-appropriate defaults
- `dev.tfvars` — dev environment (shared VPC, no cross-region)
- `staging.tfvars` — staging (shared VPC, backup replication)
- `prod.tfvars` — prod (dedicated VPC, full HA + DR)
