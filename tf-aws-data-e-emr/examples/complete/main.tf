# Complete example — long-running Spark cluster, transient Hive cluster,
# two EMR Serverless apps, an EMR Studio, KMS-backed security configuration,
# and full CloudWatch alarms.

module "emr" {
  source = "../../"

  create_iam_role                = true
  create_serverless_applications = true
  create_security_configurations = true
  create_studios                 = true
  create_alarms                  = true

  kms_key_arn         = var.kms_key_arn
  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  # ---------------------------------------------------------------------------
  # EMR Clusters
  # ---------------------------------------------------------------------------
  clusters = {
    "spark-longrunning-prod" = {
      release_label = "emr-7.0.0"
      applications  = ["Spark", "Hadoop", "JupyterEnterpriseGateway", "Hive"]
      subnet_id     = var.subnet_id
      log_uri       = "s3://${var.log_bucket}/spark-prod/"

      master_instance_type = "m5.2xlarge"
      core_instance_type   = "m5.2xlarge"
      core_instance_count  = 4
      core_ebs_size        = 128
      core_ebs_type        = "gp3"

      task_instance_type  = "m5.xlarge"
      task_instance_count = 2
      task_bid_price      = "0.20"

      keep_alive             = true
      termination_protection = true
      security_configuration = "emr-kms-security"

      configurations_json = jsonencode([
        {
          Classification = "spark-defaults"
          Properties = {
            "spark.sql.adaptive.enabled"                    = "true"
            "spark.sql.adaptive.coalescePartitions.enabled" = "true"
            "spark.dynamicAllocation.enabled"               = "true"
            "spark.serializer"                              = "org.apache.spark.serializer.KryoSerializer"
          }
        },
        {
          Classification = "hive-site"
          Properties = {
            "hive.metastore.client.factory.class" = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
          }
        }
      ])

      bootstrap_actions = [
        {
          name = "install-python-deps"
          path = "s3://${var.log_bucket}/bootstrap/install-deps.sh"
          args = ["--packages", "pandas,boto3,pyarrow"]
        },
        {
          name = "configure-hadoop"
          path = "s3://${var.log_bucket}/bootstrap/configure-hadoop.sh"
          args = []
        }
      ]

      tags = {
        Environment = "production"
        Team        = "data-engineering"
        CostCenter  = "analytics"
      }
    }

    "hive-transient-dwh" = {
      release_label = "emr-6.15.0"
      applications  = ["Hive", "Hadoop", "Tez"]
      subnet_id     = var.subnet_id
      log_uri       = "s3://${var.log_bucket}/hive-dwh/"

      master_instance_type = "r5.2xlarge"
      core_instance_type   = "r5.2xlarge"
      core_instance_count  = 6
      core_ebs_size        = 256
      core_ebs_type        = "gp3"
      use_spot_for_core    = true
      core_bid_price       = "0.30"

      keep_alive             = false
      termination_protection = false
      idle_timeout_seconds   = 7200
      security_configuration = "emr-kms-security"

      configurations_json = jsonencode([
        {
          Classification = "hive-site"
          Properties = {
            "hive.metastore.client.factory.class" = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
            "hive.exec.dynamic.partition"         = "true"
            "hive.exec.dynamic.partition.mode"    = "nonstrict"
            "hive.exec.max.dynamic.partitions"    = "10000"
            "hive.tez.container.size"             = "8192"
            "hive.tez.java.opts"                  = "-Xmx6553m"
          }
        },
        {
          Classification = "tez-site"
          Properties = {
            "tez.am.resource.memory.mb" = "8192"
          }
        }
      ])

      steps = [
        {
          name              = "run-hive-etl"
          action_on_failure = "TERMINATE_CLUSTER"
          hadoop_jar        = "command-runner.jar"
          hadoop_jar_args = [
            "hive-script",
            "--run-hive-script",
            "--args",
            "-f", "s3://${var.log_bucket}/scripts/daily_transform.hql",
            "-d", "INPUT_DATE=2024-01-01"
          ]
        }
      ]

      tags = {
        Environment = "production"
        Team        = "data-warehouse"
        ClusterType = "transient"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # EMR Serverless Applications
  # ---------------------------------------------------------------------------
  serverless_applications = {
    "serverless-spark-etl" = {
      type          = "SPARK"
      release_label = "emr-7.0.0"
      max_cpu       = "400vCPU"
      max_memory    = "3000GB"
      max_disk      = "20000GB"

      subnet_ids         = var.serverless_subnet_ids
      security_group_ids = var.serverless_security_group_ids

      auto_start           = true
      auto_stop            = true
      idle_timeout_minutes = 15

      initial_capacity = {
        "Driver" = {
          worker_count  = 2
          worker_cpu    = "4vCPU"
          worker_memory = "16GB"
          worker_disk   = "200GB"
        }
        "Executor" = {
          worker_count  = 10
          worker_cpu    = "4vCPU"
          worker_memory = "16GB"
          worker_disk   = "200GB"
        }
      }

      tags = {
        Environment = "production"
        AppType     = "serverless-spark"
      }
    }

    "serverless-hive-queries" = {
      type          = "HIVE"
      release_label = "emr-7.0.0"
      max_cpu       = "200vCPU"
      max_memory    = "1500GB"
      max_disk      = "10000GB"

      subnet_ids         = var.serverless_subnet_ids
      security_group_ids = var.serverless_security_group_ids

      auto_start           = true
      auto_stop            = true
      idle_timeout_minutes = 30

      initial_capacity = {
        "HiveDriver" = {
          worker_count  = 1
          worker_cpu    = "4vCPU"
          worker_memory = "16GB"
          worker_disk   = "200GB"
        }
        "TezTask" = {
          worker_count  = 5
          worker_cpu    = "4vCPU"
          worker_memory = "16GB"
          worker_disk   = "200GB"
        }
      }

      tags = {
        Environment = "production"
        AppType     = "serverless-hive"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Security Configurations
  # ---------------------------------------------------------------------------
  security_configurations = {
    "emr-kms-security" = {
      enable_s3_encryption         = true
      enable_local_disk_encryption = true
      enable_in_transit_encryption = false
      enable_kerberos              = false
      enable_lake_formation        = false
      kms_key_arn                  = var.kms_key_arn
    }
  }

  # ---------------------------------------------------------------------------
  # EMR Studio
  # ---------------------------------------------------------------------------
  studios = {
    "data-science-studio" = {
      auth_mode                   = "IAM"
      vpc_id                      = var.vpc_id
      subnet_ids                  = var.studio_subnet_ids
      workspace_security_group_id = var.workspace_security_group_id
      engine_security_group_id    = var.engine_security_group_id
      s3_url                      = "s3://${var.studio_s3_bucket}/workspaces/"

      tags = {
        Environment = "production"
        Purpose     = "data-science-notebooks"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Alarm thresholds
  # ---------------------------------------------------------------------------
  alarm_thresholds = {
    hdfs_utilization_percent  = 80
    live_data_nodes_min       = 2
    core_nodes_min            = 2
    capacity_remaining_gb_min = 200
  }

  tags = {
    Project     = "data-platform"
    Environment = "production"
    ManagedBy   = "terraform"
    Owner       = "data-engineering"
  }
}
