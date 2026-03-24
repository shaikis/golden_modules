# tf-aws-data-e-dms

Production-grade Terraform module for **AWS Database Migration Service (DMS)**.

Covers replication instances, source and target endpoints (all engine types), replication tasks, event subscriptions, SSL certificates, CloudWatch alarms, and required IAM roles.

---

## Features

| Feature | Default | Gate variable |
|---|---|---|
| Replication instances | always on | `var.replication_instances` map |
| Endpoints | always on | `var.endpoints` map |
| Replication tasks | always on | `var.replication_tasks` map |
| DMS event subscriptions | off | `create_event_subscriptions = true` |
| SSL certificates | off | `create_certificates = true` |
| CloudWatch alarms (5 alarms) | off | `create_alarms = true` |
| DMS IAM roles | **on** | `create_iam_roles = false` to disable |
| BYO KMS key | optional | `kms_key_arn` |

---

## Usage

### Minimal

```hcl
module "dms" {
  source = "git::https://github.com/your-org/tf-aws-data-e-dms.git?ref=v1.0.0"

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  replication_instances = {
    main = {
      replication_subnet_group_id = "main"
    }
  }

  endpoints = {
    mysql-source = {
      endpoint_type = "source"
      engine_name   = "mysql"
      server_name   = "mysql.example.com"
      port          = 3306
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme"
    }
    pg-target = {
      endpoint_type = "target"
      engine_name   = "postgres"
      server_name   = "pg.example.com"
      port          = 5432
      database_name = "appdb"
      username      = "dms_user"
      password      = "changeme"
    }
  }

  replication_tasks = {
    mysql-to-pg = {
      replication_instance_key = "main"
      source_endpoint_key      = "mysql-source"
      target_endpoint_key      = "pg-target"
    }
  }
}
```

### Complete

See [`examples/complete/`](examples/complete/).

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

---

## IAM Roles

DMS requires two IAM roles with specific, hard-coded names. When `create_iam_roles = true` (default), this module creates:

| Role name | Purpose |
|---|---|
| `dms-vpc-role` | Allows DMS to manage VPC ENIs and security groups |
| `dms-cloudwatch-logs-role` | Allows DMS to publish task logs to CloudWatch Logs |
| `dms-s3-access-role-{region}` | Allows DMS to read/write S3 for S3 endpoints |

If these roles already exist in your account, set `create_iam_roles = false` and manage them externally.

---

## Inputs

### Feature gates

| Name | Type | Default | Description |
|---|---|---|---|
| `create_alarms` | `bool` | `false` | Create CloudWatch alarms |
| `create_event_subscriptions` | `bool` | `false` | Create DMS event subscriptions |
| `create_certificates` | `bool` | `false` | Create DMS SSL certificates |
| `create_iam_roles` | `bool` | `true` | Create required DMS IAM roles |

### Primary resources

| Name | Type | Default | Description |
|---|---|---|---|
| `replication_instances` | `map(object)` | `{}` | DMS replication instance configurations |
| `endpoints` | `map(object)` | `{}` | Source and target endpoint configurations |
| `replication_tasks` | `map(object)` | `{}` | Replication task configurations |
| `subnet_groups` | `map(object)` | `{}` | DMS replication subnet groups |
| `event_subscriptions` | `map(object)` | `{}` | DMS event subscription configurations |
| `certificates` | `map(object)` | `{}` | DMS SSL certificate configurations |

### BYO resources

| Name | Type | Default | Description |
|---|---|---|---|
| `kms_key_arn` | `string` | `null` | Existing KMS key for replication instance encryption |
| `alarm_sns_topic_arn` | `string` | `null` | SNS topic for alarm notifications |

---

## Outputs

| Name | Description |
|---|---|
| `replication_instance_arns` | Map of instance key to ARN |
| `endpoint_arns` | Map of endpoint key to ARN |
| `task_arns` | Map of task key to ARN |
| `task_ids` | Map of task key to task ID |
| `dms_vpc_role_arn` | ARN of dms-vpc-role |
| `dms_logs_role_arn` | ARN of dms-cloudwatch-logs-role |
| `dms_s3_role_arn` | ARN of DMS S3 access role |
| `certificate_arns` | Map of certificate key to ARN |
| `event_subscription_arns` | Map of subscription key to ARN |
| `alarm_arns` | Map of alarm key to ARN |

---

## CloudWatch Alarms

When `create_alarms = true`, the following alarms are created per replication task:

| Alarm | Default threshold | Description |
|---|---|---|
| `CDCLatencySource` | > 60 s | Source replication lag |
| `CDCLatencyTarget` | > 60 s | Target apply lag |
| `CDCIncomingChangesHigh` | > 100,000 rows | Sudden spike in change rate |
| `FullLoadThroughputRowsTargetLow` | < 1 row/s | Full load may be stalled |
| `TableErrors` | > 0 | Any table-level error |

---

## Supported endpoint engine types

`mysql`, `postgres`, `oracle`, `sqlserver`, `aurora`, `aurora-postgresql`, `s3`, `kinesis`, `kafka`, `redshift`, `dynamodb`, `mongodb`, `docdb`, `opensearch`, `neptune`, `elasticsearch`

---

## Real-world scenarios

### 1. Oracle on-premises to S3 data lake

Migrate an on-premises Oracle database to S3 as Parquet files, forming the raw landing zone of a data lake. Use `full-load-and-cdc` migration type with `data_format = "parquet"` and `compression_type = "GZIP"`. Set `extra_connection_attributes = "addSupplementalLogging=Y"` on the Oracle source to enable CDC via LogMiner.

### 2. RDS PostgreSQL to Amazon Redshift analytics

Move transactional data into Redshift for OLAP workloads. Use the `redshift_settings` block to configure the S3 staging bucket and KMS encryption. Set `pluginName=pglogical` in `extra_connection_attributes` on the PostgreSQL source for low-impact CDC.

### 3. Homogeneous migration: MySQL RDS to Aurora MySQL

Minimal-downtime lift-and-shift of a MySQL RDS instance to Aurora MySQL. Use `migration_type = "full-load-and-cdc"` and flip the application endpoint to Aurora after full-load completes and CDC lag reaches near-zero.

### 4. Heterogeneous migration: Oracle to PostgreSQL

Convert Oracle schema and data to PostgreSQL using the AWS Schema Conversion Tool (SCT) for DDL translation, then use DMS for data movement. Set `ssl_mode = "verify-full"` with a `create_certificates = true` certificate for encrypted transit.

### 5. CDC to Amazon Kinesis Data Streams

Stream database change events to Kinesis for real-time downstream consumers (Lambda, Flink, etc.). Use `engine_name = "kinesis"` for the target endpoint and configure `kinesis_settings.message_format = "json-unformatted"` for schema-agnostic consumers.

### 6. Lift-and-shift database migration

Accelerate a large-scale database migration by running DMS with a `dms.r5.4xlarge` replication instance and `FullLoadSettings.MaxFullLoadSubTasks = 49` for maximum parallelism during the initial bulk load phase.

### 7. Cross-region database replication

Deploy separate DMS stacks in two regions, pointing at the same source. Use `publicly_accessible = false` and AWS PrivateLink or VPN for secure cross-region connectivity between the source database and the replication instance.

### 8. Minimal-downtime cutover

1. Start `full-load-and-cdc` task. 2. Monitor `CDCLatencySource` and `CDCLatencyTarget` alarms until lag < 5 seconds. 3. Put application in maintenance mode. 4. Wait for CDC lag to reach 0. 5. Stop the DMS task. 6. Point application at the new database.

### 9. Schema conversion with SCT and DMS

Use AWS SCT to generate the target schema DDL (stored procedures, functions, triggers). Apply SCT output to the target database. Then run DMS with `TargetTablePrepMode = "DO_NOTHING"` so DMS only migrates data, not DDL.

### 10. Filtering sensitive columns

Use DMS table mapping transformation rules to exclude or nullify sensitive columns (PII, payment card data) before they land in the target. Add a `transformation` rule with `rule-action = "remove-column"` for each column to exclude.

```json
{
  "rule-type": "transformation",
  "rule-id": "10",
  "rule-name": "mask-ssn",
  "rule-action": "convert-uppercase",
  "rule-target": "column",
  "object-locator": {
    "schema-name": "public",
    "table-name": "customers",
    "column-name": "ssn"
  }
}
```

### 11. Large Object (LOB) column handling

For tables with BLOB, CLOB, or TEXT columns, enable limited LOB mode in task settings: set `SupportLobs = true`, `FullLobMode = false`, `LimitedSizeLobMode = true`, and `LobMaxSize` to your largest expected LOB size in KB. For LOBs > 32 MB, use full LOB mode and accept reduced throughput.

### 12. DMS Fleet Advisor for migration planning

Before provisioning DMS resources with this module, use AWS DMS Fleet Advisor to auto-discover on-premises databases, profile schema complexity, and receive automated recommendations for replication instance sizing and migration strategy. Fleet Advisor output directly informs the `replication_instance_class` and `allocated_storage` values to use in this module.
