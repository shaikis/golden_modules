# tf-aws-data-e-stepfunctions

Production-grade Terraform module for AWS Step Functions — state machines, activities, IAM, and CloudWatch alarms.

## Features

- Map-driven `aws_sfn_state_machine` resources with `for_each`
- STANDARD and EXPRESS state machine types
- Auto-created CloudWatch Log Groups per state machine
- Structured logging with configurable levels (ALL / ERROR / FATAL / OFF)
- X-Ray tracing toggle per state machine
- Step Functions Activities (opt-in)
- CloudWatch alarms for STANDARD and EXPRESS machines (opt-in)
- Auto-created execution IAM role with granular service permission toggles
- BYO role via `role_arn` (from `tf-aws-iam`)
- BYO KMS key via `kms_key_arn` (from `tf-aws-kms`)

## Usage

### Minimal

```hcl
module "sfn" {
  source = "git::https://github.com/your-org/tf-aws-data-e-stepfunctions.git"

  state_machines = {
    etl_pipeline = {
      type       = "STANDARD"
      definition = jsonencode({ ... })
    }
  }
}
```

### With logging and tracing

```hcl
module "sfn" {
  source = "git::https://github.com/your-org/tf-aws-data-e-stepfunctions.git"

  state_machines = {
    etl_pipeline = {
      type = "STANDARD"
      definition = jsonencode({ ... })
      logging = {
        level                  = "ALL"
        include_execution_data = true
      }
      tracing_enabled = true
    }
  }
}
```

### BYO IAM role

```hcl
module "sfn" {
  source = "git::https://github.com/your-org/tf-aws-data-e-stepfunctions.git"

  create_iam_role = false
  role_arn        = module.iam.role_arn  # from tf-aws-iam

  state_machines = {
    pipeline = {
      definition = jsonencode({ ... })
    }
  }
}
```

---

## Scenarios

### 1. ETL Orchestration

Orchestrate a full ETL pipeline: Glue crawler discovers new partitions, a Glue ETL job transforms the data, results land in S3 or Redshift. Use `enable_glue_permissions = true` and set `lambda_function_arns` if Lambda handles pre/post steps. Error handling with `Retry` and `Catch` blocks sends failure alerts via SNS (`enable_sns_permissions = true`).

```hcl
module "sfn" {
  source                  = "../../"
  enable_glue_permissions = true
  enable_sns_permissions  = true
  state_machines = {
    etl = {
      type       = "STANDARD"
      definition = file("definitions/etl.json")
      logging    = { level = "ALL", include_execution_data = true }
      tracing_enabled = true
    }
  }
}
```

### 2. ML Pipeline

Run end-to-end ML workflows: data validation Lambda -> SageMaker training -> model evaluation -> Choice state routes to deploy or retraining branch. Use `enable_sagemaker_permissions = true`. Combine with `enable_lambda_permissions = true` for evaluation steps.

```hcl
module "sfn" {
  source                       = "../../"
  enable_sagemaker_permissions = true
  enable_lambda_permissions    = true
  state_machines = {
    ml_pipeline = {
      type       = "STANDARD"
      definition = file("definitions/ml_pipeline.json")
      tracing_enabled = true
    }
  }
}
```

### 3. Parallel Fan-Out

Use `Parallel` state or `Map` state for fan-out across multiple data partitions or independent services simultaneously. Each branch invokes a different Lambda or Glue job. Results are aggregated at the sync point.

```json
{
  "Type": "Parallel",
  "Branches": [
    { "StartAt": "ProcessRegionUS", "States": { ... } },
    { "StartAt": "ProcessRegionEU", "States": { ... } }
  ],
  "Next": "AggregateResults"
}
```

### 4. Human Approval Workflow

Create a Step Functions Activity for manual approval gates. The workflow pauses at a `Task` state using the activity ARN. An external worker (Lambda, EC2, or a UI) polls the activity and sends success/failure tokens to resume the workflow.

```hcl
module "sfn" {
  source            = "../../"
  create_activities = true
  activities = {
    manual_approval = {}
    human_review    = {}
  }
  state_machines = {
    approval_workflow = {
      definition = jsonencode({
        States = {
          WaitForApproval = {
            Type     = "Task"
            Resource = "arn:aws:states:us-east-1:123456789012:activity:prod-manual_approval"
            HeartbeatSeconds = 3600
            Next = "ProcessApproval"
          }
        }
      })
    }
  }
}
```

### 5. Error Handling and Retry

Every `Task` state supports `Retry` with exponential backoff and `Catch` for fallback paths. Combine with SNS alerts on failure paths and DynamoDB state tracking for audit trails.

```json
"Retry": [
  {
    "ErrorEquals": ["Lambda.ServiceException", "States.TaskFailed"],
    "IntervalSeconds": 30,
    "MaxAttempts": 3,
    "BackoffRate": 2
  }
],
"Catch": [
  {
    "ErrorEquals": ["States.ALL"],
    "Next": "HandleFailure",
    "ResultPath": "$.error"
  }
]
```

### 6. Distributed Map for Large Datasets

Use the `Map` state with `MaxConcurrency` to process thousands of S3 objects or DynamoDB records in parallel. Each iteration invokes a Lambda or Glue job. Ideal for large-scale data transformations.

```json
{
  "Type": "Map",
  "ItemsPath": "$.s3_keys",
  "MaxConcurrency": 40,
  "Iterator": {
    "StartAt": "ProcessRecord",
    "States": {
      "ProcessRecord": {
        "Type": "Task",
        "Resource": "arn:aws:lambda:...:function:process-record",
        "End": true
      }
    }
  }
}
```

### 7. Nested Workflows

Use `enable_sfn_permissions = true` to allow a parent state machine to start child state machines synchronously or asynchronously. Express workflows nested inside Standard workflows enable high-throughput sub-processing while maintaining execution history at the parent level.

```json
{
  "Type": "Task",
  "Resource": "arn:aws:states:::states:startExecution.sync:2",
  "Parameters": {
    "StateMachineArn": "arn:aws:states:us-east-1:...:stateMachine:child-workflow",
    "Input.$": "$"
  }
}
```

### 8. Saga Pattern for Distributed Transactions

Implement the saga pattern by chaining service calls with compensating transactions on failure. Each step has a corresponding rollback path in its `Catch` block. Use DynamoDB to track saga state (`enable_dynamodb_permissions = true`).

```json
{
  "StartAt": "ReserveInventory",
  "States": {
    "ReserveInventory": {
      "Type": "Task",
      "Catch": [{ "ErrorEquals": ["States.ALL"], "Next": "ReleaseInventory" }],
      "Next": "ChargePayment"
    },
    "ChargePayment": {
      "Type": "Task",
      "Catch": [{ "ErrorEquals": ["States.ALL"], "Next": "RefundPayment" }],
      "Next": "ConfirmOrder"
    }
  }
}
```

### 9. Polling with Wait State

Poll an asynchronous job (e.g. Glue, Batch, EMR) using a `Wait` state loop. A Lambda checks job status and returns a flag; a `Choice` state decides whether to wait again or proceed.

```json
{
  "CheckJobStatus": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:...:function:check-job-status",
    "Next": "IsJobComplete"
  },
  "IsJobComplete": {
    "Type": "Choice",
    "Choices": [{ "Variable": "$.status", "StringEquals": "SUCCEEDED", "Next": "ProcessResults" }],
    "Default": "WaitBeforeRetry"
  },
  "WaitBeforeRetry": {
    "Type": "Wait",
    "Seconds": 30,
    "Next": "CheckJobStatus"
  }
}
```

### 10. Callback Pattern with Task Tokens

Use `.waitForTaskToken` with Lambda, SQS, or SNS to pause execution until an external system sends a success/failure callback. Ideal for long-running operations, human-in-the-loop approvals, or third-party integrations.

```json
{
  "CallExternalSystem": {
    "Type": "Task",
    "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
    "Parameters": {
      "QueueUrl": "https://sqs.us-east-1.amazonaws.com/123456789012/approval-queue",
      "MessageBody": {
        "TaskToken.$": "$$.Task.Token",
        "Input.$": "$"
      }
    },
    "HeartbeatSeconds": 3600,
    "Next": "ProcessCallback"
  }
}
```

### 11. Express Workflow for High-Throughput

Use `type = "EXPRESS"` for high-throughput, short-duration workflows (up to 5 minutes). Express workflows can handle millions of executions per second at lower cost. Use with Kinesis, IoT, or API Gateway for real-time event processing.

```hcl
module "sfn" {
  source = "../../"
  state_machines = {
    event_processor = {
      type    = "EXPRESS"
      logging = { level = "ERROR" }
      tracing_enabled = true
      definition = jsonencode({ ... })
    }
  }
}
```

### 12. Monitoring Execution Failures

Enable `create_alarms = true` with an `alarm_sns_topic_arn` to receive alerts for failed, timed-out, aborted, and throttled executions. P99 execution time alarms catch slow workflows before they impact SLAs. Express workflow alarms monitor failure and timeout rates as percentages.

```hcl
module "sfn" {
  source                            = "../../"
  create_alarms                     = true
  alarm_sns_topic_arn               = "arn:aws:sns:us-east-1:...:alerts"
  alarm_execution_time_threshold_ms = 300000
  state_machines = { ... }
}
```

---

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_activities` | Create Step Functions activities | `bool` | `false` |
| `create_alarms` | Create CloudWatch alarms | `bool` | `false` |
| `create_iam_role` | Create execution IAM role | `bool` | `true` |
| `role_arn` | BYO IAM role ARN | `string` | `null` |
| `kms_key_arn` | BYO KMS key ARN | `string` | `null` |
| `name_prefix` | Resource name prefix | `string` | `""` |
| `tags` | Default resource tags | `map(string)` | `{}` |
| `alarm_sns_topic_arn` | SNS topic for alarm notifications | `string` | `null` |
| `alarm_execution_time_threshold_ms` | P99 execution time threshold (ms) | `number` | `300000` |
| `enable_lambda_permissions` | Grant Lambda invoke permissions | `bool` | `true` |
| `enable_glue_permissions` | Grant Glue job permissions | `bool` | `false` |
| `enable_ecs_permissions` | Grant ECS task permissions | `bool` | `false` |
| `enable_batch_permissions` | Grant Batch job permissions | `bool` | `false` |
| `enable_sagemaker_permissions` | Grant SageMaker permissions | `bool` | `false` |
| `enable_dynamodb_permissions` | Grant DynamoDB permissions | `bool` | `false` |
| `enable_sns_permissions` | Grant SNS publish permissions | `bool` | `false` |
| `enable_sqs_permissions` | Grant SQS send permissions | `bool` | `false` |
| `enable_emr_permissions` | Grant EMR cluster permissions | `bool` | `false` |
| `enable_sfn_permissions` | Grant nested SFN permissions | `bool` | `false` |
| `state_machines` | Map of state machines to create | `map(object)` | `{}` |
| `activities` | Map of activities to create | `map(object)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `state_machine_arns` | Map of key => ARN |
| `state_machine_names` | Map of key => name |
| `state_machine_creation_dates` | Map of key => creation date |
| `activity_arns` | Map of key => activity ARN |
| `sfn_role_arn` | Execution role ARN |
| `alarm_arns` | Map of alarm name => ARN |
| `log_group_arns` | Map of key => log group ARN |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0.0 |
