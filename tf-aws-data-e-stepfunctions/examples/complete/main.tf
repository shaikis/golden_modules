module "sfn" {
  source = "../../"

  name_prefix = var.name_prefix
  tags        = var.tags

  # IAM permission toggles
  create_iam_role              = true
  enable_lambda_permissions    = true
  enable_glue_permissions      = true
  enable_dynamodb_permissions  = true
  enable_sns_permissions       = true
  enable_sagemaker_permissions = true
  enable_sfn_permissions       = true

  lambda_function_arns = var.lambda_function_arns

  # Activities
  create_activities = true
  activities = {
    manual_approval = {
      tags = { Purpose = "human-approval-gate" }
    }
    human_review = {
      tags = { Purpose = "human-review-gate" }
    }
  }

  # Alarms
  create_alarms                        = true
  alarm_sns_topic_arn                  = var.alarm_sns_topic_arn
  alarm_execution_time_threshold_ms    = 300000
  alarm_express_failure_rate_threshold = 1
  alarm_express_timeout_rate_threshold = 1

  state_machines = {

    # ── 1. Daily ETL Pipeline (STANDARD) ──────────────────────────────────────
    daily_etl = {
      type = "STANDARD"
      logging = {
        level                  = "ALL"
        include_execution_data = true
      }
      tracing_enabled     = true
      publish             = true
      version_description = "v1.0 - initial daily ETL pipeline"
      definition = jsonencode({
        Comment = "Daily ETL: Glue crawler -> ETL job -> DynamoDB update -> SNS notification"
        StartAt = "StartGlueCrawler"
        States = {
          StartGlueCrawler = {
            Type     = "Task"
            Resource = "arn:aws:states:::glue:startCrawler.sync"
            Parameters = {
              Name = "raw-data-crawler"
            }
            Retry = [{
              ErrorEquals     = ["States.TaskFailed"]
              IntervalSeconds = 30
              MaxAttempts     = 3
              BackoffRate     = 2
            }]
            Catch = [{
              ErrorEquals = ["States.ALL"]
              Next        = "NotifyETLFailure"
              ResultPath  = "$.error"
            }]
            Next = "WaitForCrawler"
          }
          WaitForCrawler = {
            Type    = "Wait"
            Seconds = 60
            Next    = "StartGlueETLJob"
          }
          StartGlueETLJob = {
            Type     = "Task"
            Resource = "arn:aws:states:::glue:startJobRun.sync"
            Parameters = {
              JobName       = "daily-etl-job"
              "Arguments.$" = "$.glue_arguments"
            }
            Retry = [{
              ErrorEquals     = ["States.TaskFailed"]
              IntervalSeconds = 60
              MaxAttempts     = 2
              BackoffRate     = 2
            }]
            Catch = [{
              ErrorEquals = ["States.ALL"]
              Next        = "NotifyETLFailure"
              ResultPath  = "$.error"
            }]
            Next = "UpdateDynamoDB"
          }
          UpdateDynamoDB = {
            Type     = "Task"
            Resource = "arn:aws:states:::dynamodb:updateItem"
            Parameters = {
              TableName = "etl-pipeline-status"
              Key = {
                pipeline_id = { "S.$" = "$.pipeline_id" }
              }
              UpdateExpression = "SET #status = :status, last_run = :timestamp"
              ExpressionAttributeNames = {
                "#status" = "status"
              }
              ExpressionAttributeValues = {
                ":status"    = { S = "SUCCESS" }
                ":timestamp" = { "S.$" = "$$.Execution.StartTime" }
              }
            }
            Next = "NotifyETLSuccess"
          }
          NotifyETLSuccess = {
            Type     = "Task"
            Resource = "arn:aws:states:::sns:publish"
            Parameters = {
              TopicArn = "arn:aws:sns:us-east-1:123456789012:etl-notifications"
              Message  = "Daily ETL pipeline completed successfully."
              Subject  = "ETL Success"
            }
            End = true
          }
          NotifyETLFailure = {
            Type     = "Task"
            Resource = "arn:aws:states:::sns:publish"
            Parameters = {
              TopicArn    = "arn:aws:sns:us-east-1:123456789012:etl-notifications"
              "Message.$" = "States.Format('Daily ETL pipeline FAILED: {}', $.error.Cause)"
              Subject     = "ETL Failure Alert"
            }
            Next = "FailState"
          }
          FailState = {
            Type  = "Fail"
            Error = "ETLPipelineFailed"
            Cause = "ETL pipeline encountered an unrecoverable error"
          }
        }
      })
      tags = { Pipeline = "daily-etl" }
    }

    # ── 2. ML Training Pipeline (STANDARD) ───────────────────────────────────
    ml_training = {
      type = "STANDARD"
      logging = {
        level                  = "ALL"
        include_execution_data = true
      }
      tracing_enabled = true
      definition = jsonencode({
        Comment = "ML training: S3 check -> SageMaker training -> evaluation -> deploy or retrain"
        StartAt = "CheckS3DataAvailability"
        States = {
          CheckS3DataAvailability = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "check-s3-data-availability"
              "Payload.$"  = "$"
            }
            ResultSelector = {
              "data_ready.$"   = "$.Payload.data_ready"
              "record_count.$" = "$.Payload.record_count"
            }
            Next = "IsDataReady"
          }
          IsDataReady = {
            Type = "Choice"
            Choices = [{
              Variable      = "$.data_ready"
              BooleanEquals = true
              Next          = "StartSageMakerTraining"
            }]
            Default = "WaitForData"
          }
          WaitForData = {
            Type    = "Wait"
            Seconds = 3600
            Next    = "CheckS3DataAvailability"
          }
          StartSageMakerTraining = {
            Type     = "Task"
            Resource = "arn:aws:states:::sagemaker:createTrainingJob.sync"
            Parameters = {
              TrainingJobName = "model-training-job"
              AlgorithmSpecification = {
                TrainingImage     = "382416733822.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest"
                TrainingInputMode = "File"
              }
              RoleArn = "arn:aws:iam::123456789012:role/SageMakerRole"
              InputDataConfig = [{
                ChannelName = "training"
                DataSource = {
                  S3DataSource = {
                    S3DataType             = "S3Prefix"
                    "S3Uri.$"              = "$.s3_training_path"
                    S3DataDistributionType = "FullyReplicated"
                  }
                }
              }]
              OutputDataConfig = {
                "S3OutputPath.$" = "$.s3_output_path"
              }
              ResourceConfig = {
                InstanceType   = "ml.m5.xlarge"
                InstanceCount  = 1
                VolumeSizeInGB = 50
              }
              StoppingCondition = {
                MaxRuntimeInSeconds = 86400
              }
            }
            Next = "EvaluateModel"
          }
          EvaluateModel = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "evaluate-model-metrics"
              "Payload.$"  = "$"
            }
            ResultSelector = {
              "accuracy.$"        = "$.Payload.accuracy"
              "meets_threshold.$" = "$.Payload.meets_threshold"
            }
            Next = "ModelQualityCheck"
          }
          ModelQualityCheck = {
            Type = "Choice"
            Choices = [{
              Variable      = "$.meets_threshold"
              BooleanEquals = true
              Next          = "DeployModel"
            }]
            Default = "RetrainModel"
          }
          DeployModel = {
            Type     = "Task"
            Resource = "arn:aws:states:::sagemaker:createEndpoint.sync"
            Parameters = {
              EndpointName       = "ml-model-endpoint"
              EndpointConfigName = "ml-model-endpoint-config"
            }
            End = true
          }
          RetrainModel = {
            Type     = "Task"
            Resource = "arn:aws:states:::sns:publish"
            Parameters = {
              TopicArn = "arn:aws:sns:us-east-1:123456789012:ml-notifications"
              Message  = "Model accuracy below threshold. Queued for retraining with updated hyperparameters."
              Subject  = "ML Model Retraining Required"
            }
            End = true
          }
        }
      })
      tags = { Pipeline = "ml-training" }
    }

    # ── 3. Real-Time Processor (EXPRESS) ──────────────────────────────────────
    real_time_processor = {
      type = "EXPRESS"
      logging = {
        level                  = "ERROR"
        include_execution_data = false
      }
      tracing_enabled = true
      definition = jsonencode({
        Comment = "High-throughput real-time event processor"
        StartAt = "ValidateEvent"
        States = {
          ValidateEvent = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "validate-event"
              "Payload.$"  = "$"
            }
            ResultSelector = {
              "valid.$"         = "$.Payload.valid"
              "event_type.$"    = "$.Payload.event_type"
              "enriched_data.$" = "$.Payload.enriched_data"
            }
            Next = "RouteEvent"
          }
          RouteEvent = {
            Type = "Choice"
            Choices = [
              {
                Variable     = "$.event_type"
                StringEquals = "purchase"
                Next         = "ProcessPurchaseEvent"
              },
              {
                Variable     = "$.event_type"
                StringEquals = "clickstream"
                Next         = "ProcessClickstreamEvent"
              }
            ]
            Default = "ProcessGenericEvent"
          }
          ProcessPurchaseEvent = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "process-purchase"
              "Payload.$"  = "$.enriched_data"
            }
            Next = "WriteToDynamoDB"
          }
          ProcessClickstreamEvent = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "process-clickstream"
              "Payload.$"  = "$.enriched_data"
            }
            Next = "WriteToDynamoDB"
          }
          ProcessGenericEvent = {
            Type     = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = "process-generic-event"
              "Payload.$"  = "$.enriched_data"
            }
            Next = "WriteToDynamoDB"
          }
          WriteToDynamoDB = {
            Type     = "Task"
            Resource = "arn:aws:states:::dynamodb:putItem"
            Parameters = {
              TableName = "event-store"
              Item = {
                event_id   = { "S.$" = "$$.Execution.Name" }
                event_type = { "S.$" = "$.event_type" }
                timestamp  = { "S.$" = "$$.Execution.StartTime" }
              }
            }
            End = true
          }
        }
      })
      tags = { Pipeline = "real-time-processor" }
    }
  }
}
