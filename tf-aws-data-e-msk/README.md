# tf-aws-data-e-msk

Production-grade Terraform module for **Amazon MSK (Managed Streaming for Apache Kafka)**.

Covers provisioned clusters, serverless clusters, MSK configurations, SCRAM authentication, VPC connections, CloudWatch alarms, and IAM roles for producers and consumers.

---

## Features

| Feature | Default | Gate variable |
|---|---|---|
| Provisioned MSK clusters | always on | `var.clusters` map |
| MSK Serverless clusters | off | `create_serverless_clusters = true` |
| MSK cluster configurations | always on | `var.configurations` map |
| SCRAM secret associations | off | `create_scram_auth = true` |
| VPC connections | off | `create_vpc_connections = true` |
| CloudWatch alarms (8 alarms) | off | `create_alarms = true` |
| IAM producer + consumer roles | **on** | `create_iam_role = false` to disable |
| BYO KMS key | optional | `kms_key_arn` |
| BYO IAM role | optional | `role_arn` |

---

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

### Minimal

```hcl
module "msk" {
  source = "git::https://github.com/your-org/tf-aws-data-e-msk.git?ref=v1.0.0"

  clusters = {
    events = {
      client_subnets     = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
      security_group_ids = ["sg-xxx"]
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

## Inputs

### Feature gates

| Name | Type | Default | Description |
|---|---|---|---|
| `create_alarms` | `bool` | `false` | Create CloudWatch alarms |
| `create_serverless_clusters` | `bool` | `false` | Create MSK Serverless clusters |
| `create_vpc_connections` | `bool` | `false` | Create MSK VPC connections |
| `create_scram_auth` | `bool` | `false` | Create SCRAM secret associations |
| `create_iam_role` | `bool` | `true` | Create producer and consumer IAM roles |

### Cluster configuration (key fields)

| Name | Type | Default | Description |
|---|---|---|---|
| `clusters` | `map(object)` | `{}` | Provisioned MSK cluster configurations |
| `serverless_clusters` | `map(object)` | `{}` | MSK Serverless cluster configurations |
| `configurations` | `map(object)` | `{}` | MSK cluster configurations (Kafka broker properties) |

### BYO resources

| Name | Type | Default | Description |
|---|---|---|---|
| `kms_key_arn` | `string` | `null` | Existing KMS key for encryption at rest |
| `role_arn` | `string` | `null` | Existing IAM role to attach policies to |
| `alarm_sns_topic_arn` | `string` | `null` | SNS topic for alarm notifications |

---

## Outputs

| Name | Description |
|---|---|
| `cluster_arns` | Map of cluster key to ARN |
| `cluster_bootstrap_brokers_tls` | TLS bootstrap brokers per cluster |
| `cluster_bootstrap_brokers_sasl_iam` | SASL/IAM bootstrap brokers per cluster |
| `cluster_bootstrap_brokers_sasl_scram` | SASL/SCRAM bootstrap brokers per cluster |
| `cluster_zookeeper_connect_strings` | ZooKeeper connection strings |
| `serverless_cluster_arns` | Serverless cluster ARNs |
| `producer_role_arn` | IAM producer role ARN |
| `consumer_role_arn` | IAM consumer role ARN |
| `configuration_arns` | MSK configuration ARNs |
| `alarm_arns` | CloudWatch alarm ARNs |

---

## Real-world scenarios

### 1. Event streaming platform

Deploy a multi-AZ provisioned cluster with SASL/IAM auth and tiered storage for a platform that handles millions of events per day (user activity, clickstream, telemetry). Set `tiered_storage_enabled = true` and `storage_mode = "TIERED"` to shift cold data to S3 automatically, reducing EBS costs by up to 70%.

```hcl
clusters = {
  events = {
    instance_type          = "kafka.m5.2xlarge"
    number_of_broker_nodes = 6
    client_subnets         = var.private_subnets
    security_group_ids     = [var.msk_sg_id]
    tiered_storage_enabled = true
    storage_mode           = "TIERED"
    ebs_volume_size        = 1000
    enable_sasl_iam        = true
    enhanced_monitoring    = "PER_TOPIC_PER_BROKER"
  }
}
```

### 2. Change Data Capture (CDC)

Use MSK as the CDC event bus between Debezium (running on MSK Connect) and downstream consumers. Enable `min.insync.replicas=2` and `default.replication.factor=3` via a custom MSK configuration to guarantee durability.

```hcl
configurations = {
  cdc-config = {
    name           = "cdc-kafka-config"
    kafka_versions = ["3.5.1"]
    server_properties = <<-EOT
      auto.create.topics.enable=false
      min.insync.replicas=2
      default.replication.factor=3
      log.retention.hours=72
    EOT
  }
}
```

### 3. IoT telemetry ingestion

Ingest millions of device messages per second. Use `kafka.m5.4xlarge` brokers with provisioned throughput enabled and configure partitions per topic to parallelise ingestion across all broker nodes.

```hcl
clusters = {
  iot = {
    instance_type                     = "kafka.m5.4xlarge"
    number_of_broker_nodes            = 9
    ebs_volume_size                   = 2000
    provisioned_throughput_enabled    = true
    provisioned_throughput_volume_mbps = 1000
    client_subnets                    = var.private_subnets
    security_group_ids                = [var.msk_sg_id]
  }
}
```

### 4. Log aggregation pipeline

Replace a Logstash / Fluentd central log aggregation tier with MSK as a durable buffer. Enable S3 broker log export for long-term audit, and enable Prometheus metrics via the JMX and Node exporters for your monitoring stack.

```hcl
clusters = {
  logs = {
    instance_type         = "kafka.m5.large"
    number_of_broker_nodes = 3
    client_subnets        = var.private_subnets
    security_group_ids    = [var.msk_sg_id]
    jmx_exporter_enabled  = true
    node_exporter_enabled = true
    s3_logs_enabled       = true
    s3_logs_bucket        = "my-msk-broker-logs"
    s3_logs_prefix        = "logs-cluster/"
  }
}
```

### 5. Real-time analytics with Flink / Spark

Feed a Flink or Spark Structured Streaming job from MSK. Set `enhanced_monitoring = "PER_TOPIC_PER_BROKER"` to get per-topic consumer lag metrics in CloudWatch, enabling auto-scaling of Flink task managers based on lag.

```hcl
clusters = {
  analytics = {
    instance_type       = "kafka.m5.xlarge"
    enhanced_monitoring = "PER_TOPIC_PER_BROKER"
    client_subnets      = var.private_subnets
    security_group_ids  = [var.msk_sg_id]
    enable_sasl_iam     = true
  }
}
```

### 6. Cross-account MSK access

Allow a spoke account to produce/consume events from a hub MSK cluster using MSK VPC connections. The connection bridges the VPCs at the MSK level without requiring VPC peering or Transit Gateway.

```hcl
create_vpc_connections = true

vpc_connections = {
  spoke-account = {
    cluster_key     = "events"
    client_subnets  = ["subnet-spoke1", "subnet-spoke2"]
    security_groups = ["sg-spoke-msk"]
    vpc_id          = "vpc-spoke123"
    authentication  = "SASL_IAM"
  }
}
```

### 7. Schema Registry integration (Glue Schema Registry)

Use the AWS Glue Schema Registry with MSK for schema enforcement. Grant the producer and consumer roles `glue:GetSchema`, `glue:GetSchemaVersion`, and `glue:QuerySchemaVersionMetadata` in addition to MSK permissions. Attach these additional policies to the roles created by this module.

### 8. MSK Connect for source/sink connectors

Deploy MSK Connect workers against the provisioned cluster for Debezium CDC connectors (source) and S3 sink connectors (target). The SASL/IAM auth (`enable_sasl_iam = true`) allows MSK Connect workers to authenticate without storing credentials.

### 9. SCRAM auth for legacy clients

Legacy applications that cannot use IAM authentication can use SCRAM (username/password) stored in AWS Secrets Manager. Enable `enable_sasl_scram = true` on the cluster and use `create_scram_auth = true` with `scram_associations` to bind secrets to the cluster.

```hcl
create_scram_auth = true

scram_associations = {
  events-legacy = {
    cluster_key = "events"
    secret_arn_list = [
      "arn:aws:secretsmanager:us-east-1:123456789012:secret:msk/legacy-producer",
    ]
  }
}
```

### 10. Tiered storage for cost optimisation

Enable MSK tiered storage to automatically offload cold Kafka segments to S3, reducing the required EBS volume size significantly. Consumers transparently read from S3 for older data and from EBS for hot data.

```hcl
clusters = {
  events = {
    tiered_storage_enabled = true
    storage_mode           = "TIERED"
    ebs_volume_size        = 200  # Hot tier only
    # ...
  }
}
```

### 11. MSK Serverless for variable workloads

For workloads with unpredictable or bursty traffic (dev, staging, event-driven microservices), use MSK Serverless to eliminate capacity planning. You pay per GB of data written and read.

```hcl
create_serverless_clusters = true

serverless_clusters = {
  dev-events = {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.msk_sg_id]
  }
}
```

### 12. Disaster recovery with MirrorMaker 2 replication

For multi-region DR, deploy an MSK cluster in each region and run MirrorMaker 2 (via MSK Connect or a self-managed EC2) to replicate topics between regions. Use `kafka.m5.large` as a dedicated MirrorMaker cluster in the secondary region and `enhanced_monitoring = "PER_TOPIC_PER_BROKER"` to track replication lag.

---

## CloudWatch Alarms

When `create_alarms = true`, the following alarms are created per cluster:

| Alarm | Threshold | Severity | Description |
|---|---|---|---|
| `KafkaAppLogsDiskUsed` | > 70% | Warning | Broker disk is filling up |
| `MemoryUsed` | > 80% | Warning | Broker memory pressure |
| `CPUUser` | > 60% | Warning | Broker CPU is saturated |
| `NetworkRxDropped` | > 0 | Warning | Incoming packets being dropped |
| `NetworkTxDropped` | > 0 | Warning | Outgoing packets being dropped |
| `UnderReplicatedPartitions` | > 0 | **Critical** | Data loss risk |
| `ActiveControllerCount` | < 1 | **Critical** | No active Kafka controller |
| `OfflinePartitionsCount` | > 0 | **Critical** | Partitions unavailable |

---

## IAM Roles

Two roles are created when `create_iam_role = true`:

**Producer role** permissions:
- `kafka-cluster:Connect`
- `kafka-cluster:DescribeCluster`
- `kafka-cluster:WriteData`
- `kafka-cluster:CreateTopic`
- `kafka-cluster:DescribeTopic`

**Consumer role** permissions:
- `kafka-cluster:Connect`
- `kafka-cluster:DescribeCluster`
- `kafka-cluster:ReadData`
- `kafka-cluster:DescribeTopic`
- `kafka-cluster:AlterGroup`
- `kafka-cluster:DescribeGroup`

