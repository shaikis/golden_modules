# Complete example — 3 compute environments (Fargate Spot, EC2 Spot GPU, EC2 On-Demand),
# 3 job queues (high-priority, normal, low), 5 job definitions, fair-share scheduling, all alarms.

module "batch" {
  source = "../../"

  create_iam_role            = true
  create_scheduling_policies = true
  create_alarms              = true

  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  # ---------------------------------------------------------------------------
  # Compute Environments
  # ---------------------------------------------------------------------------
  compute_environments = {
    # Fargate Spot — cost-optimized serverless containers
    "fargate-spot-ce" = {
      type               = "MANAGED"
      compute_type       = "FARGATE_SPOT"
      max_vcpus          = 512
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
      state              = "ENABLED"
      tags = {
        CostStrategy = "fargate-spot"
        Workload     = "general-etl"
      }
    }

    # EC2 Spot — GPU instances for ML training
    "ec2-spot-gpu-ce" = {
      type                = "MANAGED"
      compute_type        = "SPOT"
      max_vcpus           = 256
      min_vcpus           = 0
      desired_vcpus       = 0
      instance_types      = ["p3.2xlarge", "p3.8xlarge", "g4dn.xlarge", "g4dn.2xlarge"]
      subnet_ids          = var.subnet_ids
      security_group_ids  = var.security_group_ids
      spot_bid_percentage = 70
      allocation_strategy = "SPOT_PRICE_CAPACITY_OPTIMIZED"
      state               = "ENABLED"
      instance_tags = {
        WorkloadType = "ml-training"
      }
      tags = {
        CostStrategy = "ec2-spot-gpu"
        Workload     = "ml-training"
      }
    }

    # EC2 On-Demand — guaranteed capacity for SLA-critical jobs
    "ec2-ondemand-ce" = {
      type                = "MANAGED"
      compute_type        = "EC2"
      max_vcpus           = 128
      min_vcpus           = 0
      desired_vcpus       = 0
      instance_types      = ["m5.2xlarge", "m5.4xlarge", "m5.8xlarge"]
      subnet_ids          = var.subnet_ids
      security_group_ids  = var.security_group_ids
      allocation_strategy = "BEST_FIT_PROGRESSIVE"
      state               = "ENABLED"
      instance_tags = {
        WorkloadType = "guaranteed-sla"
      }
      tags = {
        CostStrategy = "on-demand"
        Workload     = "sla-critical"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Fair-Share Scheduling Policies
  # ---------------------------------------------------------------------------
  scheduling_policies = {
    "fair-share-policy" = {
      compute_reservation = 30
      share_decay_seconds = 3600
      share_distributions = [
        { share_identifier = "high-priority", weight_factor = 4.0 },
        { share_identifier = "normal", weight_factor = 2.0 },
        { share_identifier = "low-priority", weight_factor = 1.0 }
      ]
      tags = {
        Purpose = "multi-tenant-fair-share"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Job Queues
  # ---------------------------------------------------------------------------
  job_queues = {
    # High-priority — SLA-critical jobs, guaranteed compute
    "high-priority-queue" = {
      priority                 = 100
      state                    = "ENABLED"
      compute_environment_keys = ["ec2-ondemand-ce", "fargate-spot-ce"]
      scheduling_policy_key    = "fair-share-policy"
      job_state_time_limit_actions = [
        {
          action           = "CANCEL"
          max_time_seconds = 600
          reason           = "Job stuck in RUNNABLE state too long — possible capacity issue"
          state            = "RUNNABLE"
        }
      ]
      tags = {
        Tier = "high-priority"
        SLA  = "critical"
      }
    }

    # Normal — standard ETL and data processing
    "normal-queue" = {
      priority                 = 50
      state                    = "ENABLED"
      compute_environment_keys = ["fargate-spot-ce", "ec2-ondemand-ce"]
      scheduling_policy_key    = "fair-share-policy"
      tags = {
        Tier = "normal"
      }
    }

    # Low-priority — background jobs, batch reports
    "low-priority-queue" = {
      priority                 = 10
      state                    = "ENABLED"
      compute_environment_keys = ["fargate-spot-ce"]
      scheduling_policy_key    = "fair-share-policy"
      tags = {
        Tier = "low-priority"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Job Definitions
  # ---------------------------------------------------------------------------
  job_definitions = {
    # ETL container — standard data transformation
    "etl-container-job" = {
      type                  = "container"
      platform_capabilities = ["FARGATE"]
      image                 = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/etl-worker:latest"
      vcpus                 = 2
      memory                = 4096
      command               = ["python3", "-m", "etl.main"]
      environment = {
        LOG_LEVEL   = "INFO"
        OUTPUT_PATH = "s3://my-data-bucket/output/"
      }
      retry_attempts      = 3
      timeout_seconds     = 7200
      propagate_tags      = true
      scheduling_priority = 10
      tags = {
        JobType = "etl"
      }
    }

    # ML training — GPU instance
    "ml-training-job" = {
      type                  = "container"
      platform_capabilities = ["EC2"]
      image                 = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ml-training:latest"
      vcpus                 = 8
      memory                = 61440
      gpu_count             = 1
      command               = ["python3", "-m", "train.main", "--epochs", "100"]
      environment = {
        LOG_LEVEL           = "INFO"
        MODEL_OUTPUT_PATH   = "s3://my-ml-bucket/models/"
        MLFLOW_TRACKING_URI = "http://mlflow.internal:5000"
      }
      retry_attempts      = 1
      timeout_seconds     = 86400
      propagate_tags      = true
      assign_public_ip    = "DISABLED"
      scheduling_priority = 50
      tags = {
        JobType = "ml-training"
        GPU     = "true"
      }
    }

    # Data quality check
    "data-quality-job" = {
      type                  = "container"
      platform_capabilities = ["FARGATE"]
      image                 = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/dq-checker:latest"
      vcpus                 = 1
      memory                = 2048
      command               = ["python3", "-m", "dq.check", "--config", "s3://my-config-bucket/dq_rules.yaml"]
      environment = {
        LOG_LEVEL      = "INFO"
        DQ_REPORT_PATH = "s3://my-data-bucket/dq-reports/"
      }
      retry_attempts      = 2
      timeout_seconds     = 3600
      propagate_tags      = true
      scheduling_priority = 20
      tags = {
        JobType = "data-quality"
      }
    }

    # Report generation
    "report-generation-job" = {
      type                  = "container"
      platform_capabilities = ["FARGATE"]
      image                 = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/report-gen:latest"
      vcpus                 = 2
      memory                = 4096
      command               = ["python3", "-m", "reports.generate"]
      environment = {
        LOG_LEVEL          = "INFO"
        REPORT_OUTPUT_PATH = "s3://my-reports-bucket/"
        EMAIL_RECIPIENTS   = "data-team@company.com"
      }
      retry_attempts      = 2
      timeout_seconds     = 3600
      propagate_tags      = true
      scheduling_priority = 5
      tags = {
        JobType = "reporting"
      }
    }

    # GPU ML inference job
    "gpu-ml-inference-job" = {
      type                  = "container"
      platform_capabilities = ["EC2"]
      image                 = "${var.ecr_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ml-inference:latest"
      vcpus                 = 4
      memory                = 30720
      gpu_count             = 1
      command               = ["python3", "-m", "inference.batch_predict"]
      environment = {
        LOG_LEVEL        = "INFO"
        MODEL_PATH       = "s3://my-ml-bucket/models/latest/"
        INFERENCE_OUTPUT = "s3://my-ml-bucket/predictions/"
      }
      retry_attempts      = 2
      timeout_seconds     = 14400
      propagate_tags      = true
      assign_public_ip    = "DISABLED"
      scheduling_priority = 30
      tags = {
        JobType = "ml-inference"
        GPU     = "true"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Alarm thresholds
  # ---------------------------------------------------------------------------
  alarm_thresholds = {
    pending_job_count_max = 50
    failed_job_count_max  = 5
  }

  tags = {
    Project     = "data-platform"
    Environment = "production"
    ManagedBy   = "terraform"
    Owner       = "data-engineering"
  }
}
