# tf-aws-data-e-stepfunctions Examples

Runnable examples for the [`tf-aws-data-e-stepfunctions`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Single STANDARD state machine that starts a Glue job synchronously — fastest path to a working Step Functions pipeline |
| [complete](complete/) | Three production state machines: daily ETL pipeline (Glue + DynamoDB + SNS), ML training pipeline (Lambda + SageMaker + Choice), and real-time event processor (EXPRESS type with Lambda fan-out) — plus Activities, CloudWatch alarms, and full IAM permission toggles |

## Architecture

```mermaid
graph TD
    subgraph Minimal["minimal/ — Single Glue ETL"]
        TRIGGER_M["EventBridge / manual"] --> SM_M["State Machine\n(STANDARD)"]
        SM_M -->|startJobRun.sync| GLUE_M["Glue ETL Job"]
    end

    subgraph Complete["complete/ — Three Pipelines"]
        subgraph ETL["daily_etl (STANDARD)"]
            EB_ETL["EventBridge Schedule"] --> ETL_SM["State Machine"]
            ETL_SM --> CRAWLER["Glue Crawler"]
            CRAWLER --> GLUE_JOB["Glue ETL Job"]
            GLUE_JOB --> DDB["DynamoDB\n(status tracking)"]
            DDB --> SNS_OK["SNS Success"]
            ETL_SM -->|Catch error| SNS_FAIL["SNS Failure Alert"]
        end

        subgraph ML["ml_training (STANDARD)"]
            EB_ML["EventBridge / manual"] --> ML_SM["State Machine"]
            ML_SM --> LAMBDA_CHECK["Lambda\n(check S3 data)"]
            LAMBDA_CHECK --> CHOICE1["Choice State\n(data ready?)"]
            CHOICE1 -->|yes| SAGEMAKER["SageMaker Training"]
            CHOICE1 -->|no| WAIT["Wait 1hr → retry"]
            SAGEMAKER --> LAMBDA_EVAL["Lambda\n(evaluate metrics)"]
            LAMBDA_EVAL --> CHOICE2["Choice State\n(accuracy ok?)"]
            CHOICE2 -->|yes| DEPLOY["SageMaker Deploy\n(create endpoint)"]
            CHOICE2 -->|no| RETRAIN["SNS Retraining Alert"]
        end

        subgraph RT["real_time_processor (EXPRESS)"]
            KINESIS["Kinesis / API GW"] --> RT_SM["State Machine\n(EXPRESS, high-throughput)"]
            RT_SM --> VALIDATE["Lambda validate"]
            VALIDATE --> ROUTE["Choice: event type"]
            ROUTE -->|purchase| PROC_P["Lambda process-purchase"]
            ROUTE -->|clickstream| PROC_C["Lambda process-clickstream"]
            PROC_P --> DDB_RT["DynamoDB event-store"]
            PROC_C --> DDB_RT
        end

        ACTIVITY["Activity\n(manual_approval)"] --> ETL_SM

        CW_ALARM["CloudWatch Alarms\n(failures / timeouts / p99)"] --> Complete
    end
```

## Quick Start

```bash
# Minimal — single Glue ETL state machine
cd minimal/
terraform init
terraform apply

# Complete — three production pipelines with alarms and activities
cd complete/
terraform init
terraform plan
terraform apply
```

## Feature Comparison

| Feature | minimal | complete |
|---------|---------|----------|
| State machines | 1 (STANDARD, Glue task) | 3 (STANDARD ETL, STANDARD ML, EXPRESS real-time) |
| IAM permission toggles | Lambda only (default) | Lambda, Glue, DynamoDB, SNS, SageMaker, nested SFN |
| Activities | No | Yes (manual_approval, human_review) |
| CloudWatch alarms | No | Yes (failure rate, timeout rate, p99 latency) |
| X-Ray tracing | No | Yes (all machines) |
| Structured logging | No | Yes (ALL level + execution data) |
| State machine versioning | No | Yes (daily_etl published with version description) |
| Error handling | No | Yes (Retry + Catch + SNS alerts) |
