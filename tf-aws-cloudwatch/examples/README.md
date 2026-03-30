# tf-aws-cloudwatch Examples

Runnable examples for the [`tf-aws-cloudwatch`](../) Terraform module.

## Available Examples

| Example | Description |
|---------|-------------|
| [complete](complete/) | Full observability stack with metric alarms for Lambda, RDS, and SQS; ASG scaling alarms; anomaly detection; composite alarm; log metric filters with alarms; CloudWatch dashboard; AWS Backup alarms; EventBridge routing; and SNS topic with email/OpsGenie/PagerDuty subscriptions |

## Architecture

```mermaid
graph TB
    subgraph Sources["Monitored Resources"]
        Lambda["Lambda Function"]
        RDS["RDS Instance"]
        SQS["SQS Queue"]
        ASG["Auto Scaling Group"]
        Backup["AWS Backup"]
        Logs["CloudWatch Log Groups"]
    end

    subgraph Alarms["CloudWatch Alarms"]
        MetricAlarms["Metric Alarms\n(errors, throttles, p99 duration,\nCPU, connections, storage,\nqueue depth, message age)"]
        AnomalyAlarms["Anomaly Detection\n(Lambda duration baseline)"]
        CompositeAlarm["Composite Alarm\n(Lambda errors AND SQS backlog)"]
        ASGAlarms["ASG Alarms\n(CPU high/low, maxed-out,\nbelow minimum, scaling failures)"]
        BackupAlarms["Backup Alarms\n(job/copy/restore failures)"]
        LogAlarms["Log Metric Filter Alarms\n(app errors, payment failures)"]
    end

    subgraph Notifications
        SNS["SNS Topic\n(KMS-encrypted)"]
        Email["Email Endpoints"]
        OpsGenie["OpsGenie"]
        PagerDuty["PagerDuty"]
        AlarmSQS["SQS Queue\n(alarm events)"]
    end

    subgraph Dashboard["CloudWatch Dashboard"]
        Widgets["Lambda + RDS + SQS + ASG Widgets"]
    end

    subgraph Routing
        EventBridge["EventBridge Rule\n(ALARM state changes)"]
        Target["EventBridge Target\n(custom ARN)"]
    end

    Sources --> Alarms
    Logs --> LogAlarms
    MetricAlarms --> SNS
    AnomalyAlarms --> SNS
    CompositeAlarm --> SNS
    ASGAlarms --> SNS
    BackupAlarms --> SNS
    LogAlarms --> SNS

    SNS --> Email
    SNS --> OpsGenie
    SNS --> PagerDuty
    SNS --> AlarmSQS

    Alarms --> Dashboard
    Alarms --> EventBridge --> Target
```

## Quick Start

```bash
cd complete/
terraform init
terraform apply -var-file="dev.tfvars"
```
