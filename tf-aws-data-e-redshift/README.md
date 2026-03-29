# tf-aws-data-e-redshift

Production-grade Terraform module for Amazon Redshift — provisioned clusters, Redshift Serverless, parameter groups, subnet groups, snapshot schedules, scheduled actions, data sharing, VPC endpoint access, CloudWatch alarms, and IAM roles.

## Design Principles

- **Choice-based**: every advanced feature is gated by a boolean variable defaulting to `false` (except `create_iam_role` and `create_subnet_groups` which default `true`)
- **BYO foundational**: accepts `role_arn` (from `tf-aws-iam`) and `kms_key_arn` (from `tf-aws-kms`) for bring-your-own patterns
- **`for_each` everywhere**: no `count` on primary resources — map-driven, composable configuration
- **`terraform fmt` clean**: all files pass `terraform fmt -check`

---

## Module Structure

```
tf-aws-data-e-redshift/
├── versions.tf            # Provider constraints + data sources
├── variables.tf           # All input variables
├── outputs.tf             # All output values
├── clusters.tf            # aws_redshift_cluster (provisioned)
├── serverless.tf          # aws_redshiftserverless_namespace + _workgroup
├── subnet_groups.tf       # aws_redshift_subnet_group
├── parameter_groups.tf    # aws_redshift_parameter_group
├── snapshots.tf           # Snapshot schedules, associations, copy grants
├── scheduled_actions.tf   # Scheduled resize/pause/resume
├── data_shares.tf         # Data share authorization + consumer association
├── endpoint_access.tf     # Managed VPC endpoint access
├── alarms.tf              # CloudWatch metric alarms
├── iam.tf                 # Redshift service + scheduler IAM roles
└── examples/
    ├── minimal/           # Single cluster, minimal config
    └── complete/          # Full production + serverless deployment
```

---

## Feature Gates

| Variable | Default | Description |
|---|---|---|
| `create_iam_role` | `true` | Create Redshift service + scheduler IAM roles |
| `create_subnet_groups` | `true` | Create Redshift subnet groups |
| `create_serverless` | `false` | Create Serverless namespaces and workgroups |
| `create_parameter_groups` | `false` | Create custom parameter groups |
| `create_snapshot_schedules` | `false` | Create snapshot schedules and associations |
| `create_scheduled_actions` | `false` | Create scheduled pause/resume/resize actions |
| `create_data_shares` | `false` | Create data share authorizations and consumer associations |
| `create_alarms` | `false` | Create CloudWatch alarms |

---

## Scenarios

### 1. Provisioned Cluster for Data Warehouse

Standard multi-node ra3 cluster for enterprise data warehousing.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  clusters = {
    prod-dw = {
      database_name          = "analytics"
      master_username        = "dwadmin"
      node_type              = "ra3.4xlarge"
      cluster_type           = "multi-node"
      number_of_nodes        = 3
      subnet_group_key       = "prod"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      encrypted              = true
      enhanced_vpc_routing   = true
      manage_master_password = true
    }
  }

  subnet_groups = {
    prod = {
      subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
    }
  }
}
```

### 2. Redshift Serverless for Ad-hoc Analytics (Pay Per Query)

Serverless — no cluster management, pay only for compute used.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_serverless    = true
  create_subnet_groups = false  # pre-existing subnets

  serverless_namespaces = {
    adhoc = {
      db_name    = "adhocdb"
      log_exports = ["connectionlog", "useractivitylog"]
    }
  }

  serverless_workgroups = {
    adhoc-wg = {
      namespace_key      = "adhoc"
      base_capacity      = 8    # 8 RPUs minimum
      max_capacity       = 128
      subnet_ids         = ["subnet-aaa", "subnet-bbb"]
      security_group_ids = ["sg-xxxxxxxx"]
    }
  }
}
```

### 3. Redshift Spectrum — Query S3 Data Lake Without Loading

Spectrum lets you query S3-resident data through external schemas backed by the Glue Data Catalog. The module's IAM role (created when `create_iam_role = true`) automatically attaches Glue catalog read permissions.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_iam_role = true   # Attaches Glue + S3 policies automatically

  clusters = {
    spectrum-dw = {
      database_name          = "warehouse"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }
}

# Then in your Redshift SQL:
# CREATE EXTERNAL SCHEMA spectrum_schema
#   FROM DATA CATALOG
#   DATABASE 'my_glue_database'
#   IAM_ROLE 'arn:aws:iam::123456789012:role/redshift-service-role-us-east-1';
```

### 4. COPY from S3 Data Lake (Batch Ingestion)

Load data from S3 into Redshift using the COPY command. The IAM role created by this module includes S3 read permissions.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_iam_role = true

  clusters = {
    ingest-dw = {
      database_name          = "datawarehouse"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
      enhanced_vpc_routing   = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }
}

# SQL to execute after deploy:
# COPY my_table FROM 's3://my-bucket/data/'
# IAM_ROLE 'arn:aws:iam::123456789012:role/redshift-service-role-us-east-1'
# FORMAT AS PARQUET;
```

### 5. UNLOAD to S3 (Export for Downstream)

Export query results to S3 for downstream analytics, ML, or archival. S3 write permissions are included in the module-created role.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_iam_role = true

  clusters = {
    export-dw = {
      database_name          = "datawarehouse"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }
}

# SQL to execute:
# UNLOAD ('SELECT * FROM my_table WHERE event_date >= CURRENT_DATE - 7')
# TO 's3://my-output-bucket/exports/weekly/'
# IAM_ROLE 'arn:aws:iam::123456789012:role/redshift-service-role-us-east-1'
# FORMAT PARQUET
# PARTITION BY (event_date);
```

### 6. Scheduled Pause/Resume for Dev Cluster (Cost Saving)

Automatically pause dev/test clusters outside business hours to eliminate compute costs when idle.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_scheduled_actions = true

  clusters = {
    dev-dw = {
      database_name          = "devdb"
      node_type              = "dc2.large"
      cluster_type           = "single-node"
      subnet_group_key       = "dev"
      vpc_security_group_ids = ["sg-dev"]
      manage_master_password = true
      skip_final_snapshot    = true
    }
  }

  subnet_groups = {
    dev = {
      subnet_ids = ["subnet-dev-aaa", "subnet-dev-bbb"]
    }
  }

  scheduled_actions = {
    dev-pause = {
      description = "Pause dev cluster at 20:00 UTC Mon-Fri"
      schedule    = "cron(0 20 ? * MON-FRI *)"
      action_type = "pause_cluster"
      cluster_key = "dev-dw"
    }
    dev-resume = {
      description = "Resume dev cluster at 07:00 UTC Mon-Fri"
      schedule    = "cron(0 7 ? * MON-FRI *)"
      action_type = "resume_cluster"
      cluster_key = "dev-dw"
    }
  }
}
```

### 7. Concurrency Scaling for Burst Workloads

Enable concurrency scaling via the `max_concurrency_scaling_clusters` parameter. The cluster automatically adds transient capacity for read queries when main cluster reaches queue depth limits.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_parameter_groups = true

  clusters = {
    burst-dw = {
      database_name          = "burstdb"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      parameter_group_key    = "concurrency-scaling"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  parameter_groups = {
    concurrency-scaling = {
      description = "Allows up to 10 concurrency scaling clusters"
      parameters = {
        max_concurrency_scaling_clusters = "10"
        enable_user_activity_logging     = "true"
      }
    }
  }
}
```

### 8. Data Sharing Across Accounts (Producer-Consumer)

Share live data from a producer cluster to a consumer account without data movement.

```hcl
# Producer account
module "redshift_producer" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_data_shares = true

  clusters = {
    producer = {
      database_name          = "salesdb"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "prod"
      vpc_security_group_ids = ["sg-prod"]
      manage_master_password = true
    }
  }

  subnet_groups = {
    prod = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  data_share_authorizations = {
    share-to-analytics = {
      data_share_arn      = "arn:aws:redshift:us-east-1:111111111111:datashare:producer/sales_share"
      consumer_identifier = "222222222222"   # consumer AWS account ID
      allow_writes        = false
    }
  }
}

# Consumer account — uses data_share_consumer_associations
module "redshift_consumer" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_data_shares = true

  # Consumer cluster configuration omitted for brevity

  data_share_consumer_associations = {
    receive-sales-share = {
      data_share_arn           = "arn:aws:redshift:us-east-1:111111111111:datashare:producer/sales_share"
      associate_entire_account = true
    }
  }
}
```

### 9. Federated Queries to RDS/Aurora

Query data in RDS or Aurora directly from Redshift without ETL. The module IAM role includes Athena permissions needed for federated query execution.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_iam_role = true  # Includes Athena + Glue permissions

  clusters = {
    federated-dw = {
      database_name          = "warehouse"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
      enhanced_vpc_routing   = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }
}

# SQL — create external schema pointing to Aurora PostgreSQL:
# CREATE EXTERNAL SCHEMA apg_schema
#   FROM POSTGRES
#   DATABASE 'aurora_db'
#   URI 'aurora-cluster.cluster-xxxx.us-east-1.rds.amazonaws.com'
#   IAM_ROLE 'arn:aws:iam::123456789012:role/redshift-service-role-us-east-1'
#   SECRET_ARN 'arn:aws:secretsmanager:us-east-1:123456789012:secret:aurora-creds';
```

### 10. Zero-ETL Integration with Aurora

Zero-ETL replicates Aurora data into Redshift automatically. No Terraform resources are needed for the integration itself — it is configured in the Aurora cluster and Redshift side. However, the Redshift cluster must be properly configured.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_parameter_groups = true

  clusters = {
    zeroetl-target = {
      database_name          = "zeroetldb"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      parameter_group_key    = "zeroetl"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
      enhanced_vpc_routing   = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  parameter_groups = {
    zeroetl = {
      description = "Zero-ETL compatible parameter group"
      parameters = {
        enable_case_sensitive_identifier = "true"
      }
    }
  }
}

# After apply: create the integration in the AWS Console or via Aurora module,
# then in Redshift SQL:
# CREATE DATABASE aurora_replica FROM INTEGRATION '<integration-id>';
```

### 11. Cross-Region Snapshot Copy for Disaster Recovery

Copy automated snapshots to another region for DR using snapshot copy grants.

```hcl
# Primary region (us-east-1)
module "redshift_primary" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  create_snapshot_schedules = true

  clusters = {
    dr-primary = {
      database_name          = "warehouse"
      node_type              = "ra3.xlplus"
      cluster_type           = "multi-node"
      number_of_nodes        = 2
      subnet_group_key       = "main"
      vpc_security_group_ids = ["sg-xxxxxxxx"]
      manage_master_password = true
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }

  snapshot_schedules = {
    hourly = {
      description  = "Hourly snapshot for DR"
      definitions  = ["cron(0 * * * ? *)"]
      cluster_keys = ["dr-primary"]
    }
  }

  # Cross-region copy grant (destination region's KMS key)
  snapshot_copy_grants = {
    dr-grant = {
      snapshot_copy_grant_name = "redshift-dr-copy-grant"
      kms_key_id               = "arn:aws:kms:us-west-2:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  }
}

# Enable cross-region copy on the cluster (AWS Console or CLI):
# aws redshift enable-snapshot-copy \
#   --cluster-identifier dr-primary \
#   --destination-region us-west-2 \
#   --snapshot-copy-grant-name redshift-dr-copy-grant \
#   --retention-period 7
```

### 12. Aqua (Advanced Query Accelerator) for ra3 Clusters

AQUA is a distributed hardware-accelerated cache for ra3 clusters that can improve query performance up to 10x for scan-heavy workloads.

```hcl
module "redshift" {
  source = "github.com/your-org/tf-aws-data-e-redshift"

  clusters = {
    aqua-dw = {
      database_name             = "analytics"
      node_type                 = "ra3.4xlarge"   # AQUA requires ra3 node types
      cluster_type              = "multi-node"
      number_of_nodes           = 2
      subnet_group_key          = "main"
      vpc_security_group_ids    = ["sg-xxxxxxxx"]
      manage_master_password    = true
      aqua_configuration_status = "enabled"       # "enabled", "disabled", or "auto"
    }
  }

  subnet_groups = {
    main = {
      subnet_ids = ["subnet-aaa", "subnet-bbb"]
    }
  }
}
```

---

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |

## Providers

| Name | Version |
|---|---|
| aws | >= 5.0.0 |

## Inputs

### Feature Gates

| Name | Type | Default | Description |
|---|---|---|---|
| `create_iam_role` | `bool` | `true` | Create Redshift service and scheduler IAM roles |
| `create_subnet_groups` | `bool` | `true` | Create Redshift subnet groups |
| `create_serverless` | `bool` | `false` | Create Serverless namespaces and workgroups |
| `create_parameter_groups` | `bool` | `false` | Create custom parameter groups |
| `create_snapshot_schedules` | `bool` | `false` | Create snapshot schedules |
| `create_scheduled_actions` | `bool` | `false` | Create scheduled cluster actions |
| `create_data_shares` | `bool` | `false` | Create data share resources |
| `create_alarms` | `bool` | `false` | Create CloudWatch alarms |

### BYO Foundational

| Name | Type | Default | Description |
|---|---|---|---|
| `role_arn` | `string` | `null` | BYO IAM role ARN (from `tf-aws-iam`) |
| `kms_key_arn` | `string` | `null` | BYO KMS key ARN (from `tf-aws-kms`) |
| `alarm_sns_topic_arn` | `string` | `null` | SNS topic ARN for alarm notifications |

### Maps

| Name | Type | Description |
|---|---|---|
| `clusters` | `map(object)` | Provisioned cluster configurations |
| `subnet_groups` | `map(object)` | Subnet group configurations |
| `parameter_groups` | `map(object)` | Parameter group configurations |
| `serverless_namespaces` | `map(object)` | Serverless namespace configurations |
| `serverless_workgroups` | `map(object)` | Serverless workgroup configurations |
| `snapshot_schedules` | `map(object)` | Snapshot schedule configurations |
| `snapshot_copy_grants` | `map(object)` | Cross-region snapshot copy grant configurations |
| `scheduled_actions` | `map(object)` | Scheduled action configurations |
| `data_share_authorizations` | `map(object)` | Data share authorization configurations |
| `data_share_consumer_associations` | `map(object)` | Data share consumer association configurations |
| `endpoint_accesses` | `map(object)` | Managed VPC endpoint access configurations |

## Outputs

| Name | Description |
|---|---|
| `cluster_ids` | Map of cluster key to cluster identifier |
| `cluster_arns` | Map of cluster key to cluster ARN |
| `cluster_endpoints` | Map of cluster key to endpoint address |
| `cluster_port` | Map of cluster key to port |
| `cluster_dns_names` | Map of cluster key to DNS name |
| `serverless_namespace_arns` | Map of namespace key to ARN |
| `serverless_workgroup_arns` | Map of workgroup key to ARN |
| `serverless_workgroup_endpoints` | Map of workgroup key to endpoint |
| `subnet_group_names` | Map of subnet group key to name |
| `parameter_group_names` | Map of parameter group key to name |
| `redshift_role_arn` | Redshift service IAM role ARN |
| `scheduled_action_role_arn` | Scheduler IAM role ARN |
| `snapshot_schedule_arns` | Map of schedule key to ARN |
| `alarm_arns` | Map of alarm key to CloudWatch alarm ARN |
| `endpoint_access_addresses` | Map of endpoint key to VPC endpoint address |
| `aws_region` | Deployment AWS region |
| `aws_account_id` | Deployment AWS account ID |

---

## IAM Roles Created

When `create_iam_role = true` (default), the module creates two roles:

**Redshift Service Role** (`redshift-service-role-<region>`):
- Trust: `redshift.amazonaws.com`
- `AmazonRedshiftFullAccess` managed policy
- S3 read/write policy (COPY and UNLOAD commands)
- Glue Data Catalog read policy (Redshift Spectrum)
- Athena query policy (federated queries)

**Redshift Scheduler Role** (`redshift-scheduler-role-<region>`):
- Trust: `scheduler.redshift.amazonaws.com`
- Inline policy: `redshift:PauseCluster`, `redshift:ResumeCluster`, `redshift:ResizeCluster`

---

## Supported Node Types

| Node Type | Use Case |
|---|---|
| `dc2.large` | Dev/test, small workloads (SSD-based) |
| `dc2.8xlarge` | Performance-sensitive, medium workloads |
| `ra3.xlplus` | Managed storage, general purpose |
| `ra3.4xlarge` | Managed storage, larger workloads |
| `ra3.16xlarge` | Managed storage, largest workloads, AQUA-eligible |

---

## Quick Start

```bash
cd examples/minimal
terraform init
terraform plan
terraform apply
```

```bash
cd examples/complete
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

---

## License

MIT

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.

