# tf-aws-data-e-eventbridge Examples

Runnable examples for the [`tf-aws-data-e-eventbridge`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [minimal](minimal/) | Minimal configuration — single scheduled rule (daily cron) with a Lambda target |
| [complete](complete/) | Full configuration with custom event buses (orders, inventory, audit), 8 pattern and scheduled rules, API destinations (Slack, PagerDuty), EventBridge Pipes with DynamoDB stream filtering and SQS delivery, schema registry with auto-discovery, event archives, and CloudWatch alarms |

## Architecture

```mermaid
graph LR
    subgraph Sources["Event Sources"]
        AWS["AWS Services\n(S3 · DynamoDB · GuardDuty)"]
        SCHED["Scheduled Rules\n(cron)"]
        PIPES["EventBridge Pipes\n(DynamoDB stream)"]
    end
    subgraph Processing["Amazon EventBridge"]
        BUS["Custom Event Buses\n(orders · audit)"]
        RULES["Rules\n(pattern · schedule)"]
    end
    subgraph Destinations["Targets"]
        LAMBDA["Lambda"]
        SFN["Step Functions"]
        SNS["SNS"]
        SQS["SQS FIFO"]
        API["API Destinations\n(Slack · PagerDuty)"]
    end
    Sources --> BUS
    BUS --> RULES
    RULES --> LAMBDA
    RULES --> SFN
    RULES --> SNS
    PIPES --> SQS
    RULES --> API
```

## Quick Start

```bash
cd minimal/
terraform init
terraform apply -var-file="dev.tfvars"
```
