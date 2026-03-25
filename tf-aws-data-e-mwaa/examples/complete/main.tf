module "mwaa" {
  source = "../../"

  name_prefix = var.name_prefix
  tags        = var.tags
  kms_key_arn = var.kms_key_arn

  # IAM role — shared across both environments
  create_iam_role              = true
  enable_glue_permissions      = true
  enable_emr_permissions       = true
  enable_redshift_permissions  = true
  enable_sagemaker_permissions = true
  enable_lambda_permissions    = true
  enable_sfn_permissions       = true

  # Alarms
  create_alarms                  = true
  alarm_sns_topic_arn            = var.alarm_sns_topic_arn
  alarm_queued_tasks_threshold   = 20
  alarm_pending_tasks_threshold  = 20
  alarm_dag_parse_time_threshold = 60

  environments = {

    # ── Production — mw1.large ─────────────────────────────────────────────────
    prod = {
      airflow_version   = "2.8.1"
      environment_class = "mw1.large"
      max_workers       = 25
      min_workers       = 2
      schedulers        = 2

      source_bucket_arn      = var.prod_source_bucket_arn
      dag_s3_path            = "dags/"
      requirements_s3_path   = "requirements/requirements.txt"
      plugins_s3_path        = "plugins/plugins.zip"
      startup_script_s3_path = "scripts/startup.sh"

      webserver_access_mode           = "PRIVATE_ONLY"
      weekly_maintenance_window_start = "MON:01:00"

      subnet_ids         = var.prod_subnet_ids
      security_group_ids = var.prod_security_group_ids

      airflow_configuration_options = {
        "core.parallelism"                    = "256"
        "core.max_active_tasks_per_dag"       = "256"
        "core.max_active_runs_per_dag"        = "16"
        "scheduler.dag_dir_list_interval"     = "30"
        "scheduler.min_file_process_interval" = "30"
        "celery.worker_concurrency"           = "16"
        "celery.sync_parallelism"             = "1"
        "webserver.dag_default_view"          = "grid"
        "logging.logging_level"               = "INFO"
        "secrets.backend"                     = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
        "secrets.backend_kwargs"              = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\"}"
      }

      dag_processing_logs_level = "WARNING"
      scheduler_logs_level      = "WARNING"
      task_logs_level           = "INFO"
      webserver_logs_level      = "WARNING"
      worker_logs_level         = "WARNING"

      tags = {
        Environment = "prod"
        CostCenter  = "DE-001"
        Tier        = "production"
      }
    }

    # ── Development — mw1.small ────────────────────────────────────────────────
    dev = {
      airflow_version   = "2.8.1"
      environment_class = "mw1.small"
      max_workers       = 5
      min_workers       = 1
      schedulers        = 2

      source_bucket_arn    = var.dev_source_bucket_arn
      dag_s3_path          = "dags/"
      requirements_s3_path = "requirements/requirements.txt"

      webserver_access_mode           = "PRIVATE_ONLY"
      weekly_maintenance_window_start = "SAT:02:00"

      subnet_ids         = var.dev_subnet_ids
      security_group_ids = var.dev_security_group_ids

      airflow_configuration_options = {
        "core.parallelism"                = "32"
        "core.max_active_tasks_per_dag"   = "32"
        "core.max_active_runs_per_dag"    = "4"
        "scheduler.dag_dir_list_interval" = "60"
        "logging.logging_level"           = "DEBUG"
        "secrets.backend"                 = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
        "secrets.backend_kwargs"          = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\"}"
      }

      dag_processing_logs_level = "INFO"
      scheduler_logs_level      = "INFO"
      task_logs_level           = "DEBUG"
      webserver_logs_level      = "INFO"
      worker_logs_level         = "INFO"

      tags = {
        Environment = "dev"
        CostCenter  = "DE-001"
        Tier        = "development"
      }
    }
  }
}
