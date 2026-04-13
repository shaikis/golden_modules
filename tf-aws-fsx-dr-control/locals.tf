locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-fsx-dr-control"
    },
    var.tags
  )

  state_table_name = var.create_state_table ? aws_dynamodb_table.dr_state[0].name : var.state_table_name

  lambda_env = {
    STATE_TABLE_NAME        = local.state_table_name != null ? local.state_table_name : ""
    DEFAULT_SNS_TOPIC_ARN   = var.notification_topic_arn != null ? var.notification_topic_arn : ""
    DEFAULT_ROUTE53_ZONE_ID = var.dns != null ? var.dns.zone_id : ""
    DEFAULT_ROUTE53_NAME    = var.dns != null ? var.dns.record_name : ""
    DEFAULT_ROUTE53_TYPE    = var.dns != null ? var.dns.record_type : ""
    DEFAULT_ROUTE53_TTL     = tostring(var.dns != null ? var.dns.ttl : 30)
  }

  step_function_definition = jsonencode({
    Comment = "FSx ONTAP DR control workflow"
    StartAt = "Precheck"
    States = {
      Precheck = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"
        Parameters = {
          FunctionName = aws_lambda_function.controller.arn
          Payload = {
            action              = "precheck"
            "execution_input.$" = "$"
          }
        }
        Next = "HasOntapActions"
      }
      HasOntapActions = {
        Type = "Choice"
        Choices = [
          {
            Variable  = "$.execution_input.ontap_actions[0]"
            IsPresent = true
            Next      = "RunOntapActions"
          }
        ]
        Default = "HasDnsChange"
      }
      RunOntapActions = {
        Type      = "Map"
        ItemsPath = "$.execution_input.ontap_actions"
        Parameters = {
          "action.$"            = "$$.Map.Item.Value.action"
          "secret_arn.$"        = "$$.Map.Item.Value.secret_arn"
          "method.$"            = "$$.Map.Item.Value.method"
          "path.$"              = "$$.Map.Item.Value.path"
          "body.$"              = "$$.Map.Item.Value.body"
          "query.$"             = "$$.Map.Item.Value.query"
          "expected_statuses.$" = "$$.Map.Item.Value.expected_statuses"
          "validate_certs.$"    = "$$.Map.Item.Value.validate_certs"
        }
        Iterator = {
          StartAt = "InvokeOntapAction"
          States = {
            InvokeOntapAction = {
              Type       = "Task"
              Resource   = "arn:aws:states:::lambda:invoke"
              OutputPath = "$.Payload"
              Parameters = {
                FunctionName = aws_lambda_function.controller.arn
                "Payload.$"  = "$"
              }
              End = true
            }
          }
        }
        ResultPath = "$.ontap_action_results"
        Next       = "HasDnsChange"
      }
      HasDnsChange = {
        Type = "Choice"
        Choices = [
          {
            Variable  = "$.execution_input.dns_change.action"
            IsPresent = true
            Next      = "UpdateDns"
          }
        ]
        Default = "HasStateRecord"
      }
      UpdateDns = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"
        Parameters = {
          FunctionName = aws_lambda_function.controller.arn
          "Payload.$"  = "$.execution_input.dns_change"
        }
        ResultPath = "$.dns_result"
        Next       = "HasStateRecord"
      }
      HasStateRecord = {
        Type = "Choice"
        Choices = [
          {
            Variable  = "$.execution_input.state_record.action"
            IsPresent = true
            Next      = "RecordState"
          }
        ]
        Default = "HasNotification"
      }
      RecordState = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"
        Parameters = {
          FunctionName = aws_lambda_function.controller.arn
          "Payload.$"  = "$.execution_input.state_record"
        }
        ResultPath = "$.state_result"
        Next       = "HasNotification"
      }
      HasNotification = {
        Type = "Choice"
        Choices = [
          {
            Variable  = "$.execution_input.notification.action"
            IsPresent = true
            Next      = "Notify"
          }
        ]
        Default = "Done"
      }
      Notify = {
        Type       = "Task"
        Resource   = "arn:aws:states:::lambda:invoke"
        OutputPath = "$.Payload"
        Parameters = {
          FunctionName = aws_lambda_function.controller.arn
          "Payload.$"  = "$.execution_input.notification"
        }
        ResultPath = "$.notification_result"
        Next       = "Done"
      }
      Done = {
        Type = "Succeed"
      }
    }
  })
}
