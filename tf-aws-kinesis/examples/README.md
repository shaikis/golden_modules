# tf-aws-kinesis — Examples

> Quick-start examples for the `tf-aws-kinesis` Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single ON_DEMAND Kinesis Data Stream with KMS encryption and no additional resources — ideal for getting started or low-traffic pipelines |
| [complete](complete/) | Full production setup: three streams (ON_DEMAND + PROVISIONED), Firehose to S3 and Redshift, Flink analytics application, Enhanced Fan-Out consumer, IAM roles, and CloudWatch alarms |

## Architecture

```mermaid
graph TB
    subgraph Producers
        P1[IoT / Web Apps]
        P2[Lambda Functions]
        P3[CDC via DMS]
    end

    subgraph KDS["Kinesis Data Streams"]
        S1["Stream: events\n(ON_DEMAND)"]
        S2["Stream: orders\n(4 shards, 168 h ret.)"]
        S3["Stream: clickstream\n(8 shards, 48 h ret.)"]
    end

    subgraph Consumers
        EFO["Enhanced Fan-Out\nConsumer (EFO)\n2 MB/s per shard"]
        FH1["Firehose → S3\n(GZIP, dyn. partition)"]
        FH2["Firehose → Redshift\n(+ S3 backup)"]
        FLINK["Kinesis Analytics v2\nApache Flink 1.18"]
    end

    subgraph Destinations
        S3L["S3 Data Lake\nHive-partitioned prefixes"]
        RS["Amazon Redshift"]
        CWA["CloudWatch Alarms\n→ SNS → PagerDuty"]
    end

    KMS["AWS KMS\n(Server-Side Encryption)"]

    P1 -->|PutRecords| S1
    P1 -->|PutRecords| S2
    P2 -->|PutRecords| S3
    P3 -->|PutRecords| S2

    S1 --> FH1
    S2 --> EFO
    S2 --> FH2
    S3 --> FLINK

    FH1 --> S3L
    FH2 --> RS
    FLINK --> S3L

    KMS -.->|encrypt| S1
    KMS -.->|encrypt| S2
    KMS -.->|encrypt| S3

    S2 --> CWA
    S3 --> CWA
```

## Running an Example

```bash
cd minimal
terraform init
terraform apply

# For the complete example, supply variable values first:
cd complete
terraform init
terraform apply -var-file="prod.tfvars"
```
