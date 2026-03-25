# tf-aws-data-e-eventbridge

Production-grade Terraform module for **Amazon EventBridge** — custom event buses, rules, targets, Pipes, API destinations, schema registries, archives, and CloudWatch alarms.

## Features

- Custom event buses (with optional KMS encryption and SaaS partner sources)
- Event rules (scheduled cron/rate and pattern-based)
- All target types: Lambda, SQS, SNS, Kinesis, Firehose, Step Functions, ECS, Batch, API Gateway, API Destinations, CloudWatch Logs, SageMaker
- Input transformers for reshaping event payloads
- Retry policy and dead-letter queue per target
- EventBridge Pipes (DynamoDB/Kinesis/SQS → filter → enrich → target)
- API connections (API key, Basic, OAuth 2.0)
- HTTP API destinations (Slack, PagerDuty, webhooks)
- Event archives with configurable retention and pattern filtering
- Schema registries, schemas, and auto-discoverers
- CloudWatch alarms: FailedInvocations, ThrottledRules, DeadLetterInvocations, MatchedEvents=0
- Optional IAM role creation with per-target-type permission gates
- BYO IAM role and KMS key (from external modules)
- All feature gates default to `false` — opt-in only
- `for_each` throughout

## Module Structure

| File | Purpose |
|---|---|
| `buses.tf` | Custom event buses |
| `rules.tf` | Event rules (scheduled + pattern-based) |
| `targets.tf` | Rule targets (all target types) |
| `connections.tf` | API connections for HTTP targets |
| `api_destinations.tf` | HTTP API destinations |
| `archives.tf` | Event archives for replay |
| `pipes.tf` | EventBridge Pipes |
| `schemas.tf` | Schema registry, schemas, discoverers |
| `alarms.tf` | CloudWatch alarms per rule |
| `iam.tf` | IAM roles for EventBridge and Pipes |

## Usage Scenarios

### 1. Scheduled ETL Trigger

Trigger a Step Functions state machine on a cron schedule.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  enable_stepfunctions_target = true

  rules = {
    daily_etl = {
      schedule_expression = "cron(0 2 * * ? *)"
      description         = "Daily ETL pipeline at 02:00 UTC."
    }
  }

  targets = {
    daily_etl_sfn = {
      rule_key = "daily_etl"
      arn      = "arn:aws:states:us-east-1:123456789012:stateMachine:etl-pipeline"
      input    = jsonencode({ environment = "prod" })
    }
  }
}
```

### 2. S3 Event → Lambda

Trigger a Lambda function when a new object lands in an S3 bucket.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  rules = {
    s3_ingest = {
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail      = { bucket = { name = ["my-data-bucket"] } }
      })
    }
  }

  targets = {
    s3_ingest_lambda = {
      rule_key = "s3_ingest"
      arn      = "arn:aws:lambda:us-east-1:123456789012:function:process-s3-object"
    }
  }
}
```

### 3. DynamoDB Streams via Pipes

Filter DynamoDB INSERT events, enrich via Lambda, and route to SQS FIFO.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_pipes = true

  pipes = {
    orders_pipe = {
      source = "arn:aws:dynamodb:us-east-1:123456789012:table/orders/stream/latest"
      target = "arn:aws:sqs:us-east-1:123456789012:order-processing.fifo"

      source_parameters = {
        filter_criteria = {
          filters = [{ pattern = jsonencode({ eventName = ["INSERT"] }) }]
        }
        dynamodb_stream_parameters = {
          starting_position = "TRIM_HORIZON"
          batch_size        = 10
        }
      }

      enrichment = "arn:aws:lambda:us-east-1:123456789012:function:enrich-order"

      target_parameters = {
        sqs_queue_parameters = { message_group_id = "orders" }
      }
    }
  }
}
```

### 4. Microservices Decoupling

Create custom event buses per domain and route events between services.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_custom_buses = true

  event_buses = {
    orders    = { tags = { Domain = "orders" } }
    inventory = { tags = { Domain = "inventory" } }
    payments  = { tags = { Domain = "payments" } }
  }

  rules = {
    order_placed = {
      event_bus_key = "orders"
      event_pattern = jsonencode({
        source      = ["com.myapp.orders"]
        detail-type = ["order.placed"]
      })
    }
  }

  targets = {
    order_placed_inventory = {
      rule_key = "order_placed"
      arn      = "arn:aws:lambda:us-east-1:123456789012:function:reserve-inventory"
    }
  }
}
```

### 5. Cross-Account Event Routing

Route events from one account's bus to another account's bus.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  rules = {
    forward_to_central = {
      event_pattern = jsonencode({
        source = ["com.myapp"]
      })
    }
  }

  targets = {
    central_bus = {
      rule_key = "forward_to_central"
      # Target is the event bus ARN in the central account
      arn = "arn:aws:events:us-east-1:999888777666:event-bus/central"
    }
  }
}
```

### 6. SaaS Integration via Partner Sources

Ingest events from an EventBridge SaaS partner (e.g., Datadog, Auth0).

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_custom_buses = true

  event_buses = {
    auth0_events = {
      event_source_name = "aws.partner/auth0.com/tenant-id/default"
    }
  }

  rules = {
    auth0_login = {
      event_bus_key = "auth0_events"
      event_pattern = jsonencode({
        detail-type = ["Auth0 log"]
        detail      = { data = { type = ["s"] } }
      })
    }
  }

  targets = {
    auth0_login_lambda = {
      rule_key = "auth0_login"
      arn      = "arn:aws:lambda:us-east-1:123456789012:function:process-login"
    }
  }
}
```

### 7. API Destination to Slack / PagerDuty

Send events to external HTTP APIs with auth, rate limiting, and input transformation.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_api_connections  = true
  create_api_destinations = true
  enable_api_destination_target = true

  api_connections = {
    slack = {
      authorization_type = "API_KEY"
      api_key_name       = "Content-Type"
      api_key_value      = "application/json"
    }
  }

  api_destinations = {
    slack_webhook = {
      connection_key      = "slack"
      invocation_endpoint = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      http_method         = "POST"
      invocation_rate_limit_per_second = 5
    }
  }

  rules = {
    alert_rule = {
      event_pattern = jsonencode({ source = ["com.myapp.alerts"] })
    }
  }

  targets = {
    alert_slack = {
      rule_key = "alert_rule"
      arn      = "arn:aws:events:us-east-1:123456789012:api-destination/slack_webhook"
      input_transformer = {
        input_paths    = { message = "$.detail.message" }
        input_template = "{\"text\": \"<message>\"}"
      }
    }
  }
}
```

### 8. Event Archiving + Replay

Archive all events from a custom bus and configure retention.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_custom_buses = true
  create_archives     = true

  event_buses = {
    orders = {}
  }

  archives = {
    orders_90d = {
      event_source_arn = "arn:aws:events:us-east-1:123456789012:event-bus/orders"
      retention_days   = 90
      description      = "Archive order events for 90 days."
    }
  }
}
```

### 9. Filtering with input_transformer

Reshape CloudTrail events before passing to Lambda.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  rules = {
    iam_changes = {
      event_pattern = jsonencode({
        source      = ["aws.iam"]
        detail-type = ["AWS API Call via CloudTrail"]
        detail      = { eventName = ["CreateUser", "DeleteUser", "AttachUserPolicy"] }
      })
    }
  }

  targets = {
    iam_audit = {
      rule_key = "iam_changes"
      arn      = "arn:aws:lambda:us-east-1:123456789012:function:audit-iam-changes"
      input_transformer = {
        input_paths = {
          user      = "$.detail.requestParameters.userName"
          action    = "$.detail.eventName"
          actor     = "$.detail.userIdentity.arn"
          timestamp = "$.time"
        }
        input_template = "{\"user\": \"<user>\", \"action\": \"<action>\", \"actor\": \"<actor>\", \"at\": \"<timestamp>\"}"
      }
    }
  }
}
```

### 10. ECS Task Trigger on Schedule

Run an ECS Fargate task on a cron schedule for batch processing.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  enable_ecs_target = true

  rules = {
    weekly_report = {
      schedule_expression = "cron(0 6 ? * MON *)"
      description         = "Run weekly report ECS task every Monday at 06:00 UTC."
    }
  }

  targets = {
    weekly_ecs_task = {
      rule_key = "weekly_report"
      arn      = "arn:aws:ecs:us-east-1:123456789012:cluster/batch-cluster"
      ecs_target = {
        task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/weekly-report:5"
        cluster_arn         = "arn:aws:ecs:us-east-1:123456789012:cluster/batch-cluster"
        launch_type         = "FARGATE"
        task_count          = 1
        subnet_ids          = ["subnet-abc123"]
        security_group_ids  = ["sg-abc123"]
        assign_public_ip    = false
        container_overrides = [
          {
            name    = "report-runner"
            command = ["python", "run_report.py"]
            environment = {
              REPORT_DATE = "MONDAY"
              OUTPUT_S3   = "s3://reports-bucket/weekly/"
            }
          }
        ]
      }
    }
  }
}
```

### 11. GuardDuty to SIEM Forwarding

Route GuardDuty findings to a SIEM via Kinesis Firehose.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  enable_kinesis_target = true

  rules = {
    guardduty_to_siem = {
      event_pattern = jsonencode({
        source      = ["aws.guardduty"]
        detail-type = ["GuardDuty Finding"]
      })
    }
  }

  targets = {
    guardduty_firehose = {
      rule_key = "guardduty_to_siem"
      arn      = "arn:aws:firehose:us-east-1:123456789012:deliverystream/siem-delivery"
    }
  }
}
```

### 12. Schema Discovery for Event Contracts

Auto-discover and register schemas from event bus traffic.

```hcl
module "eventbridge" {
  source = "github.com/your-org/tf-aws-data-e-eventbridge"

  create_custom_buses      = true
  create_schema_registries = true

  event_buses = {
    platform = {}
  }

  schema_registries = {
    platform_schemas = {
      description = "Auto-discovered and hand-crafted platform event schemas."
    }
  }

  schema_discoverers = {
    platform_discoverer = {
      event_bus_key = "platform"
      description   = "Auto-discover schemas from platform bus."
    }
  }

  schemas = {
    order_created = {
      registry_key = "platform_schemas"
      type         = "OpenApi3"
      description  = "Order created event schema."
      content = jsonencode({
        openapi = "3.0.0"
        info    = { title = "OrderCreated", version = "1.0.0" }
        paths   = {}
        components = {
          schemas = {
            OrderCreated = {
              type       = "object"
              properties = { orderId = { type = "string" }, amount = { type = "number" } }
              required   = ["orderId", "amount"]
            }
          }
        }
      })
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `create_custom_buses` | Create custom event buses | `bool` | `false` | no |
| `create_api_connections` | Create API connections | `bool` | `false` | no |
| `create_api_destinations` | Create API destinations | `bool` | `false` | no |
| `create_archives` | Create event archives | `bool` | `false` | no |
| `create_pipes` | Create EventBridge Pipes | `bool` | `false` | no |
| `create_schema_registries` | Create schema registries | `bool` | `false` | no |
| `create_alarms` | Create CloudWatch alarms | `bool` | `false` | no |
| `create_iam_role` | Create EventBridge IAM role | `bool` | `true` | no |
| `role_arn` | Existing IAM role ARN (BYO) | `string` | `null` | no |
| `kms_key_arn` | KMS key ARN (BYO) | `string` | `null` | no |
| `alarm_sns_topic_arn` | SNS topic for alarm notifications | `string` | `null` | no |
| `enable_lambda_target` | Enable Lambda target permissions | `bool` | `true` | no |
| `enable_sqs_target` | Enable SQS target permissions | `bool` | `false` | no |
| `enable_sns_target` | Enable SNS target permissions | `bool` | `false` | no |
| `enable_kinesis_target` | Enable Kinesis target permissions | `bool` | `false` | no |
| `enable_stepfunctions_target` | Enable Step Functions permissions | `bool` | `false` | no |
| `enable_ecs_target` | Enable ECS target permissions | `bool` | `false` | no |
| `enable_batch_target` | Enable Batch target permissions | `bool` | `false` | no |
| `event_buses` | Custom event buses | `map(object)` | `{}` | no |
| `rules` | Event rules | `map(object)` | `{}` | no |
| `targets` | Rule targets | `map(object)` | `{}` | no |
| `api_connections` | API connections | `map(object)` | `{}` | no |
| `api_destinations` | API destinations | `map(object)` | `{}` | no |
| `archives` | Event archives | `map(object)` | `{}` | no |
| `pipes` | EventBridge Pipes | `map(object)` | `{}` | no |
| `schema_registries` | Schema registries | `map(object)` | `{}` | no |
| `schemas` | Schemas | `map(object)` | `{}` | no |
| `schema_discoverers` | Schema discoverers | `map(object)` | `{}` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `event_bus_arns` | Map of custom event bus ARNs |
| `rule_arns` | Map of rule ARNs |
| `rule_names` | Map of rule names |
| `archive_arns` | Map of archive ARNs |
| `pipe_arns` | Map of Pipe ARNs |
| `schema_registry_arns` | Map of schema registry ARNs |
| `eventbridge_role_arn` | EventBridge invocation IAM role ARN |
| `pipes_role_arn` | EventBridge Pipes IAM role ARN |
| `alarm_arns` | Map of CloudWatch alarm ARNs |
| `api_destination_arns` | Map of API destination ARNs |
| `aws_account_id` | AWS account ID |
| `aws_region` | AWS region |

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3.0 |
| aws | >= 5.0.0 |
