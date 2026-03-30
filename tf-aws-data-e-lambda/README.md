# tf-aws-lambda

Terraform module for AWS Lambda functions.

## Features

- Auto-creates execution IAM role with configurable policies
- VPC support (auto-attaches VPC execution policy)
- KMS encryption for environment variables
- X-Ray tracing enabled by default
- CloudWatch log group with configurable retention and KMS
- `publish = true` with alias support
- Event source mappings (SQS, DynamoDB, Kinesis)
- Lambda permissions/triggers map
- Dead letter queue (SQS/SNS)
- Lambda layers support

## Security Controls

| Control | Default |
|---------|---------|
| X-Ray tracing | `Active` |
| KMS env var encryption | Optional (`kms_key_arn`) |
| Log retention | 30 days |
| Reserved concurrency | `-1` (no throttle; set explicitly for prod) |
| VPC | Optional |

## Versioning

Review [CHANGELOG.md](CHANGELOG.md) before selecting a module version. Use explicit git tags such as `?ref=v1.0.0`, `?ref=v1.1.0`, or `?ref=v2.0.0` so deployments stay predictable.
## Usage

```hcl
module "lambda" {
  source        = "git::https://github.com/your-org/tf-modules.git//tf-aws-lambda?ref=v1.0.0"
  function_name = "data-processor"
  handler       = "app.handler"
  runtime       = "python3.12"
  filename      = "${path.module}/package.zip"
  source_code_hash = filebase64sha256("${path.module}/package.zip")
  kms_key_arn   = module.kms.key_arn
}
```

## Architecture

```mermaid
graph TD
    subgraph EventSources["Event Sources"]
        KDS[Kinesis Data Stream\nevent-source-mapping]
        SQS[SQS Queue\nevent-source-mapping]
        DDB[DynamoDB Stream\nevent-source-mapping]
        EB[EventBridge Scheduler\ncron / rate trigger]
        APIGW[API Gateway\nresource-based permission]
        SNS_T[SNS Topic\nresource-based permission]
    end

    subgraph LambdaModule["Lambda Function"]
        FN[aws_lambda_function\nruntime · handler · memory · timeout]
        ALIAS[Aliases\nlive · canary]
        ESM[Event Source Mappings\nbatch-size · filter-criteria · parallelization]
        LAYER[Lambda Layers\nshared dependencies]
        DLQ[Dead Letter Queue\nSQS / SNS]
    end

    subgraph Compute["Execution Environment"]
        VPC[VPC\nsubnet · security-group]
        EFS[EFS Access Point\n/mnt/data]
        XRAY[X-Ray Tracing\nActive mode]
    end

    subgraph IAM["IAM"]
        ROLE[Execution Role\nauto-created or BYO]
        POL[Inline + Managed Policies]
    end

    subgraph Destinations["Async Destinations"]
        ON_S[On-Success\nSQS / SNS / Lambda]
        ON_F[On-Failure\nSQS / SNS / Lambda]
    end

    subgraph Ops["Observability"]
        CWL[CloudWatch Logs\nconfigurable retention]
        CWA[CloudWatch Alarms\nerrors · throttles · duration]
        CWD[CloudWatch Dashboard]
        INSIGHTS[Lambda Insights]
    end

    KDS -->|ESM poll| ESM
    SQS -->|ESM poll| ESM
    DDB -->|ESM poll| ESM
    EB -->|schedule trigger| FN
    APIGW -->|invoke| FN
    SNS_T -->|invoke| FN

    ESM --> FN
    FN --> ALIAS
    FN -.->|attaches| LAYER
    FN -->|on error| DLQ

    ROLE --> FN
    POL --> ROLE

    FN -.->|runs in| VPC
    FN -.->|mounts| EFS
    FN --> XRAY

    FN -->|async success| ON_S
    FN -->|async failure| ON_F

    FN --> CWL
    CWL --> CWA
    CWA --> CWD
    FN --> INSIGHTS
```

## Examples

- [Basic](examples/basic/)
- [Complete](examples/complete/)

