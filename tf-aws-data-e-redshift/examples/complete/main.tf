module "redshift" {
  source = "../../"

  # ── Feature Gates ────────────────────────────────────────────────────────────
  create_serverless         = true
  create_subnet_groups      = true
  create_parameter_groups   = true
  create_snapshot_schedules = true
  create_scheduled_actions  = true
  create_data_shares        = true
  create_alarms             = true
  create_iam_role           = true

  # ── BYO Foundational ─────────────────────────────────────────────────────────
  kms_key_arn         = var.kms_key_arn
  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  # ── Alarm thresholds ─────────────────────────────────────────────────────────
  alarm_cpu_threshold             = 85
  alarm_connections_threshold     = 1000
  alarm_disk_threshold            = 80
  alarm_read_latency_threshold    = 0.05
  alarm_write_latency_threshold   = 0.05
  alarm_compute_seconds_threshold = 7200

  # ── Subnet Groups ─────────────────────────────────────────────────────────────
  subnet_groups = {
    prod = {
      description = "Production subnet group for Redshift"
      subnet_ids  = var.prod_subnet_ids
    }
    dev = {
      description = "Dev/test subnet group for Redshift"
      subnet_ids  = var.dev_subnet_ids
    }
  }

  # ── Parameter Groups ──────────────────────────────────────────────────────────
  parameter_groups = {
    prod = {
      description = "Production parameter group — strict SSL, activity logging"
      parameters = {
        require_ssl                      = "true"
        enable_user_activity_logging     = "true"
        use_fips_ssl                     = "false"
        max_concurrency_scaling_clusters = "3"
      }
    }
    dev = {
      description = "Dev parameter group — relaxed settings"
      parameters = {
        require_ssl                      = "false"
        enable_user_activity_logging     = "false"
        max_concurrency_scaling_clusters = "1"
      }
    }
  }

  # ── Provisioned Clusters ──────────────────────────────────────────────────────
  clusters = {
    # Production ra3.4xlarge, 3 nodes, multi-AZ, KMS-encrypted, Spectrum-ready
    prod-dw = {
      database_name                       = "analytics"
      master_username                     = "dwadmin"
      node_type                           = "ra3.4xlarge"
      cluster_type                        = "multi-node"
      number_of_nodes                     = 3
      subnet_group_key                    = "prod"
      parameter_group_key                 = "prod"
      vpc_security_group_ids              = var.prod_security_group_ids
      encrypted                           = true
      enhanced_vpc_routing                = true
      publicly_accessible                 = false
      manage_master_password              = true
      automated_snapshot_retention_period = 7
      preferred_maintenance_window        = "sun:03:00-sun:04:00"
      logging_enabled                     = true
      log_destination_type                = "cloudwatch"
      skip_final_snapshot                 = false
      final_snapshot_identifier           = "prod-dw-final"
      multi_az                            = true
      aqua_configuration_status           = "enabled"
      tags = {
        Tier       = "production"
        Compliance = "PCI-DSS"
        CostCenter = "data-platform"
      }
    }

    # Dev cluster (single-node dc2.large, scheduled pause/resume)
    dev-dw = {
      database_name                       = "devdb"
      master_username                     = "devadmin"
      node_type                           = "dc2.large"
      cluster_type                        = "single-node"
      number_of_nodes                     = 1
      subnet_group_key                    = "dev"
      parameter_group_key                 = "dev"
      vpc_security_group_ids              = var.dev_security_group_ids
      encrypted                           = true
      enhanced_vpc_routing                = false
      publicly_accessible                 = false
      manage_master_password              = true
      automated_snapshot_retention_period = 1
      preferred_maintenance_window        = "sat:06:00-sat:07:00"
      logging_enabled                     = false
      skip_final_snapshot                 = true
      tags = {
        Tier       = "development"
        AutoPause  = "true"
        CostCenter = "engineering"
      }
    }
  }

  # ── Serverless ────────────────────────────────────────────────────────────────
  serverless_namespaces = {
    adhoc = {
      db_name               = "adhocdb"
      admin_username        = "svcadmin"
      manage_admin_password = true
      log_exports           = ["connectionlog", "useractivitylog", "userlog"]
      tags = {
        Tier    = "serverless"
        UseCase = "ad-hoc-analytics"
      }
    }
  }

  serverless_workgroups = {
    adhoc-wg = {
      namespace_key        = "adhoc"
      base_capacity        = 32
      max_capacity         = 128
      subnet_ids           = var.prod_subnet_ids
      security_group_ids   = var.prod_security_group_ids
      publicly_accessible  = false
      enhanced_vpc_routing = true
      config_parameters = {
        max_query_execution_time = "3600"
        datestyle                = "ISO, MDY"
      }
      tags = {
        Tier    = "serverless"
        UseCase = "ad-hoc-analytics"
      }
    }
  }

  # ── Snapshot Schedules ────────────────────────────────────────────────────────
  snapshot_schedules = {
    daily-prod = {
      description  = "Daily snapshot of production cluster at 02:00 UTC"
      definitions  = ["cron(0 2 * * ? *)"]
      cluster_keys = ["prod-dw"]
      tags = {
        Purpose = "disaster-recovery"
      }
    }
  }

  # ── Scheduled Actions (pause/resume dev cluster) ───────────────────────────
  scheduled_actions = {
    dev-dw-pause = {
      description = "Pause dev cluster at 20:00 UTC on weekdays"
      schedule    = "cron(0 20 ? * MON-FRI *)"
      action_type = "pause_cluster"
      cluster_key = "dev-dw"
      enable      = true
    }
    dev-dw-resume = {
      description = "Resume dev cluster at 07:00 UTC on weekdays"
      schedule    = "cron(0 7 ? * MON-FRI *)"
      action_type = "resume_cluster"
      cluster_key = "dev-dw"
      enable      = true
    }
    prod-dw-resize-down = {
      description     = "Scale prod cluster down on weekends"
      schedule        = "cron(0 22 ? * FRI *)"
      action_type     = "resize_cluster"
      cluster_key     = "prod-dw"
      enable          = true
      node_type       = "ra3.4xlarge"
      cluster_type    = "multi-node"
      number_of_nodes = 2
    }
    prod-dw-resize-up = {
      description     = "Scale prod cluster back up on Monday mornings"
      schedule        = "cron(0 5 ? * MON *)"
      action_type     = "resize_cluster"
      cluster_key     = "prod-dw"
      enable          = true
      node_type       = "ra3.4xlarge"
      cluster_type    = "multi-node"
      number_of_nodes = 3
    }
  }

  # ── Data Shares ───────────────────────────────────────────────────────────────
  data_share_authorizations = {
    prod-to-analytics = {
      data_share_arn      = "arn:aws:redshift:us-east-1:PRODUCER_ACCOUNT:datashare:prod-dw/sales_share"
      consumer_identifier = var.analytics_consumer_account_id
      allow_writes        = false
    }
  }

  tags = var.tags
}
