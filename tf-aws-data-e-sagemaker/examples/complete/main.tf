# ---------------------------------------------------------------------------
# Complete Example — Domain + User Profiles + Pipelines + Models +
#                    Endpoint (A/B test) + Feature Groups + All Alarms
# ---------------------------------------------------------------------------

module "sagemaker" {
  source = "../.."

  # Feature gates
  create_iam_role       = true
  create_pipelines      = true
  create_models         = true
  create_endpoints      = true
  create_feature_groups = true
  create_user_profiles  = true
  create_alarms         = true

  # Foundational
  kms_key_arn         = var.kms_key_arn
  data_bucket_arns    = var.data_bucket_arns
  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  # ── Studio Domain ──────────────────────────────────────────────────────────
  domains = {
    "ml-studio-prod" = {
      auth_mode               = "IAM"
      vpc_id                  = var.vpc_id
      subnet_ids              = var.subnet_ids
      app_network_access_type = "VpcOnly"
      kms_key_id              = var.kms_key_arn
    }
  }

  # ── User Profiles ──────────────────────────────────────────────────────────
  user_profiles = {
    "data-scientist-alice" = {
      domain_key = "ml-studio-prod"
    }
    "ml-engineer-bob" = {
      domain_key = "ml-studio-prod"
    }
  }

  # ── Pipelines ─────────────────────────────────────────────────────────────
  pipelines = {
    "customer-churn-training" = {
      display_name       = "Customer Churn Training Pipeline"
      description        = "XGBoost training pipeline for customer churn prediction."
      max_parallel_steps = 3
      pipeline_definition = jsonencode({
        Version = "2020-12-01"
        Steps = [
          {
            Name = "PreprocessingStep"
            Type = "Processing"
            Arguments = {
              ProcessingJobName = "churn-preprocessing"
              ProcessingResources = {
                ClusterConfig = {
                  InstanceCount  = 1
                  InstanceType   = "ml.m5.xlarge"
                  VolumeSizeInGB = 30
                }
              }
              AppSpecification = {
                ImageUri = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.2-1"
              }
            }
          },
          {
            Name      = "TrainingStep"
            Type      = "Training"
            DependsOn = ["PreprocessingStep"]
            Arguments = {
              AlgorithmSpecification = {
                TrainingImage     = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
                TrainingInputMode = "File"
              }
              ResourceConfig = {
                InstanceCount  = 1
                InstanceType   = "ml.m5.2xlarge"
                VolumeSizeInGB = 50
              }
              HyperParameters = {
                max_depth   = "6"
                eta         = "0.2"
                num_round   = "100"
                objective   = "binary:logistic"
                eval_metric = "auc"
              }
            }
          }
        ]
      })
    }

    "batch-inference-pipeline" = {
      display_name       = "Batch Inference Pipeline"
      description        = "Nightly batch scoring using Transform jobs."
      max_parallel_steps = 2
      pipeline_definition = jsonencode({
        Version = "2020-12-01"
        Steps = [
          {
            Name = "TransformStep"
            Type = "Transform"
            Arguments = {
              ModelName = "churn-model-champion"
              TransformResources = {
                InstanceCount = 2
                InstanceType  = "ml.m5.xlarge"
              }
              TransformInput = {
                DataSource = {
                  S3DataSource = {
                    S3DataType = "S3Prefix"
                    S3Uri      = "s3://my-data-bucket/batch-input/"
                  }
                }
                ContentType = "text/csv"
              }
              TransformOutput = {
                S3OutputPath = "s3://my-data-bucket/batch-output/"
              }
            }
          }
        ]
      })
    }
  }

  # ── Models ────────────────────────────────────────────────────────────────
  models = {
    "churn-model-champion" = {
      primary_container = {
        image_uri      = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
        model_data_url = "s3://my-data-bucket/models/champion/model.tar.gz"
        environment = {
          SAGEMAKER_CONTAINER_LOG_LEVEL = "20"
          SAGEMAKER_REGION              = "us-east-1"
        }
      }
      vpc_subnet_ids         = var.subnet_ids
      vpc_security_group_ids = []
    }
    "churn-model-challenger" = {
      primary_container = {
        image_uri      = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1"
        model_data_url = "s3://my-data-bucket/models/challenger/model.tar.gz"
        environment = {
          SAGEMAKER_CONTAINER_LOG_LEVEL = "20"
          SAGEMAKER_REGION              = "us-east-1"
        }
      }
      vpc_subnet_ids         = var.subnet_ids
      vpc_security_group_ids = []
    }
  }

  # ── Endpoint Configurations ────────────────────────────────────────────────
  endpoint_configurations = {
    "churn-ab-test-config" = {
      kms_key_arn = var.kms_key_arn
      production_variants = [
        {
          variant_name           = "Champion"
          model_key              = "churn-model-champion"
          instance_type          = "ml.m5.xlarge"
          initial_instance_count = 2
          initial_variant_weight = 0.9
        },
        {
          variant_name           = "Challenger"
          model_key              = "churn-model-challenger"
          instance_type          = "ml.m5.xlarge"
          initial_instance_count = 1
          initial_variant_weight = 0.1
        }
      ]
      data_capture_enabled           = true
      data_capture_s3_uri            = "s3://my-data-bucket/data-capture/"
      data_capture_sample_percentage = 20
      data_capture_options           = ["Input", "Output"]
    }
  }

  # ── Endpoints ─────────────────────────────────────────────────────────────
  endpoints = {
    "churn-prediction-endpoint" = {
      endpoint_config_key = "churn-ab-test-config"
    }
  }

  # ── Feature Groups ────────────────────────────────────────────────────────
  feature_groups = {
    "user-features" = {
      record_identifier_feature_name = "user_id"
      event_time_feature_name        = "event_time"
      online_store_enabled           = true
      offline_store_bucket           = var.offline_feature_store_bucket
      offline_store_prefix           = "user-features"
      offline_data_format            = "Parquet"
      offline_table_format           = "Glue"
      features = [
        { name = "user_id", type = "String" },
        { name = "event_time", type = "String" },
        { name = "age", type = "Integral" },
        { name = "tenure_months", type = "Integral" },
        { name = "monthly_spend", type = "Fractional" },
        { name = "num_products", type = "Integral" },
        { name = "churn_risk_score", type = "Fractional" },
      ]
    }
    "item-features" = {
      record_identifier_feature_name = "item_id"
      event_time_feature_name        = "event_time"
      online_store_enabled           = false
      offline_store_bucket           = var.offline_feature_store_bucket
      offline_store_prefix           = "item-features"
      offline_data_format            = "Parquet"
      offline_table_format           = "Iceberg"
      features = [
        { name = "item_id", type = "String" },
        { name = "event_time", type = "String" },
        { name = "category", type = "String" },
        { name = "price", type = "Fractional" },
        { name = "avg_rating", type = "Fractional" },
        { name = "num_reviews", type = "Integral" },
      ]
    }
  }

  tags = {
    Environment = "production"
    Project     = "ml-platform"
    ManagedBy   = "terraform"
  }
}
