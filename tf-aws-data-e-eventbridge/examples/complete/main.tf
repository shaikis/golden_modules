module "eventbridge" {
  source = "../../"

  # ── IAM ──────────────────────────────────────────────────────────────────────
  create_iam_role               = true
  iam_role_name                 = "eventbridge-invocation-role-${var.environment}"
  pipes_role_name               = "eventbridge-pipes-role-${var.environment}"
  enable_lambda_target          = true
  enable_sqs_target             = true
  enable_sns_target             = true
  enable_kinesis_target         = true
  enable_stepfunctions_target   = true
  enable_ecs_target             = true
  enable_batch_target           = false
  enable_api_destination_target = true

  # ── Custom Event Buses ────────────────────────────────────────────────────────
  create_custom_buses = true

  event_buses = {
    orders = {
      tags = { Domain = "orders" }
    }
    inventory = {
      tags = { Domain = "inventory" }
    }
    audit = {
      tags = { Domain = "audit", Compliance = "required" }
    }
  }

  # ── Rules ─────────────────────────────────────────────────────────────────────
  rules = {
    # 1. S3 object created → trigger Glue crawler
    s3_object_created = {
      description   = "Trigger Glue crawler when new objects land in S3."
      event_bus_key = null
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = { name = ["my-datalake-raw-${var.account_id}"] }
        }
      })
      state = "ENABLED"
    }

    # 2. DynamoDB stream change → Lambda processor
    ddb_stream_changes = {
      description   = "Route DynamoDB stream records to Lambda via EventBridge Pipes."
      event_bus_key = "orders"
      event_pattern = jsonencode({
        source      = ["aws.dynamodb"]
        detail-type = ["DynamoDB Stream Record"]
      })
    }

    # 3. Scheduled ETL trigger (daily at 02:00 UTC)
    scheduled_etl = {
      description         = "Daily ETL pipeline trigger."
      schedule_expression = "cron(0 2 * * ? *)"
      state               = "ENABLED"
    }

    # 4. GuardDuty finding → SNS alert
    guardduty_finding = {
      description = "Alert on GuardDuty HIGH/CRITICAL findings."
      event_pattern = jsonencode({
        source      = ["aws.guardduty"]
        detail-type = ["GuardDuty Finding"]
        detail = {
          severity = [{ numeric = [">=", 7] }]
        }
      })
    }

    # 5. CloudTrail API call → audit log bus
    cloudtrail_api_audit = {
      description   = "Route CloudTrail management events to audit bus."
      event_bus_key = "audit"
      event_pattern = jsonencode({
        source      = ["aws.cloudtrail"]
        detail-type = ["AWS API Call via CloudTrail"]
      })
    }

    # 6. CodePipeline state change → Slack via API destination
    codepipeline_state = {
      description = "Notify Slack on CodePipeline state changes."
      event_pattern = jsonencode({
        source      = ["aws.codepipeline"]
        detail-type = ["CodePipeline Pipeline Execution State Change"]
      })
    }

    # 7. RDS maintenance → PagerDuty
    rds_maintenance = {
      description = "Alert PagerDuty on RDS maintenance events."
      event_pattern = jsonencode({
        source      = ["aws.rds"]
        detail-type = ["RDS DB Instance Event"]
        detail = {
          EventCategories = ["maintenance"]
        }
      })
    }

    # 8. EC2 state change → CMDB Lambda
    ec2_state_change = {
      description = "Update CMDB on EC2 instance state changes."
      event_pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
        detail = {
          state = ["running", "stopped", "terminated"]
        }
      })
    }
  }

  # ── Targets ───────────────────────────────────────────────────────────────────
  targets = {
    s3_to_glue_crawler = {
      rule_key              = "s3_object_created"
      arn                   = "arn:aws:glue:${var.aws_region}:${var.account_id}:crawler/raw-data-crawler"
      target_id             = "GlueCrawlerTarget"
      retry_attempts        = 3
      max_event_age_seconds = 3600
      dead_letter_queue_arn = "arn:aws:sqs:${var.aws_region}:${var.account_id}:eventbridge-dlq"
    }

    ddb_stream_lambda = {
      rule_key  = "ddb_stream_changes"
      arn       = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:process-order-stream"
      target_id = "OrderStreamProcessor"
      input_transformer = {
        input_paths = {
          eventName  = "$.detail.eventName"
          tableName  = "$.detail.tableName"
          recordKeys = "$.detail.dynamodb.keys"
        }
        input_template = "{\"event\": \"<eventName>\", \"table\": \"<tableName>\", \"keys\": <recordKeys>}"
      }
    }

    scheduled_etl_sfn = {
      rule_key  = "scheduled_etl"
      arn       = "arn:aws:states:${var.aws_region}:${var.account_id}:stateMachine:daily-etl-pipeline"
      target_id = "ETLStateMachine"
      input     = jsonencode({ pipeline = "daily-etl", environment = var.environment })
    }

    guardduty_sns = {
      rule_key  = "guardduty_finding"
      arn       = "arn:aws:sns:${var.aws_region}:${var.account_id}:security-alerts"
      target_id = "SecurityAlertSNS"
      input_transformer = {
        input_paths = {
          severity    = "$.detail.severity"
          type        = "$.detail.type"
          description = "$.detail.description"
          region      = "$.region"
          account     = "$.account"
        }
        input_template = "{\"severity\": \"<severity>\", \"type\": \"<type>\", \"description\": \"<description>\", \"region\": \"<region>\", \"account\": \"<account>\"}"
      }
    }

    cloudtrail_audit_lambda = {
      rule_key  = "cloudtrail_api_audit"
      arn       = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:audit-logger"
      target_id = "AuditLogger"
    }

    codepipeline_slack = {
      rule_key  = "codepipeline_state"
      arn       = "arn:aws:events:${var.aws_region}:${var.account_id}:api-destination/slack-webhook"
      target_id = "SlackNotification"
      input_transformer = {
        input_paths = {
          pipeline = "$.detail.pipeline"
          state    = "$.detail.state"
        }
        input_template = "{\"text\": \"Pipeline *<pipeline>* changed state to *<state>*\"}"
      }
    }

    rds_pagerduty = {
      rule_key  = "rds_maintenance"
      arn       = "arn:aws:events:${var.aws_region}:${var.account_id}:api-destination/pagerduty"
      target_id = "PagerDutyAlert"
    }

    ec2_cmdb_lambda = {
      rule_key  = "ec2_state_change"
      arn       = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:update-cmdb"
      target_id = "CMDBUpdater"
      input_transformer = {
        input_paths = {
          instance_id = "$.detail.instance-id"
          state       = "$.detail.state"
          region      = "$.region"
        }
        input_template = "{\"instance_id\": \"<instance_id>\", \"state\": \"<state>\", \"region\": \"<region>\"}"
      }
    }
  }

  # ── API Connections ───────────────────────────────────────────────────────────
  create_api_connections = true

  api_connections = {
    slack = {
      description        = "Slack incoming webhook connection."
      authorization_type = "API_KEY"
      api_key_name       = "Content-Type"
      api_key_value      = "application/json"
    }
    pagerduty = {
      description        = "PagerDuty Events API v2 connection."
      authorization_type = "API_KEY"
      api_key_name       = "Authorization"
      api_key_value      = "Token token=placeholder"
    }
  }

  # ── API Destinations ──────────────────────────────────────────────────────────
  create_api_destinations = true

  api_destinations = {
    slack-webhook = {
      connection_key                   = "slack"
      invocation_endpoint              = var.slack_webhook_url
      http_method                      = "POST"
      description                      = "Post messages to Slack."
      invocation_rate_limit_per_second = 10
    }
    pagerduty = {
      connection_key                   = "pagerduty"
      invocation_endpoint              = var.pagerduty_endpoint
      http_method                      = "POST"
      description                      = "Create PagerDuty incidents."
      invocation_rate_limit_per_second = 10
    }
  }

  # ── Archives ──────────────────────────────────────────────────────────────────
  create_archives = true

  archives = {
    orders_archive = {
      event_source_arn = "arn:aws:events:${var.aws_region}:${var.account_id}:event-bus/orders"
      description      = "Archive all order domain events for 90 days."
      retention_days   = 90
    }
    audit_archive = {
      event_source_arn = "arn:aws:events:${var.aws_region}:${var.account_id}:event-bus/audit"
      description      = "Archive audit events for compliance (1 year)."
      retention_days   = 365
      event_pattern = jsonencode({
        source = ["aws.cloudtrail"]
      })
    }
  }

  # ── Pipes ─────────────────────────────────────────────────────────────────────
  create_pipes = true

  pipes = {
    ddb_to_sqs = {
      description = "DynamoDB stream → filter new records → enrich → SQS FIFO."
      source      = "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/orders/stream/latest"
      target      = "arn:aws:sqs:${var.aws_region}:${var.account_id}:order-processing.fifo"

      source_parameters = {
        filter_criteria = {
          filters = [{ pattern = jsonencode({ eventName = ["INSERT"] }) }]
        }
        dynamodb_stream_parameters = {
          starting_position = "TRIM_HORIZON"
          batch_size        = 10
        }
      }

      enrichment                = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:enrich-order"
      enrichment_input_template = "{\"orderId\": \"<$.dynamodb.NewImage.id.S>\"}"

      target_parameters = {
        input_template = "{\"order\": <$.body>}"
        sqs_queue_parameters = {
          message_group_id = "orders"
        }
      }

      tags = { Component = "pipes" }
    }
  }

  # ── Schema Registries ─────────────────────────────────────────────────────────
  create_schema_registries = true

  schema_registries = {
    platform_events = {
      description = "Platform domain event schemas."
      tags        = { Domain = "platform" }
    }
  }

  schemas = {
    order_created_v1 = {
      registry_key = "platform_events"
      type         = "OpenApi3"
      description  = "Schema for order.created v1 events."
      content = jsonencode({
        openapi = "3.0.0"
        info    = { title = "OrderCreated", version = "1.0.0" }
        paths   = {}
        components = {
          schemas = {
            OrderCreated = {
              type = "object"
              properties = {
                orderId    = { type = "string" }
                customerId = { type = "string" }
                amount     = { type = "number" }
                currency   = { type = "string" }
                createdAt  = { type = "string", format = "date-time" }
              }
              required = ["orderId", "customerId", "amount"]
            }
          }
        }
      })
    }
  }

  schema_discoverers = {
    orders_discoverer = {
      event_bus_key = "orders"
      description   = "Auto-discover schemas from orders event bus."
    }
  }

  # ── CloudWatch Alarms ─────────────────────────────────────────────────────────
  create_alarms            = true
  alarm_sns_topic_arn      = var.alarm_sns_topic_arn
  alarm_period_seconds     = 300
  alarm_evaluation_periods = 1

  tags = var.tags
}
