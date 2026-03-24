# ---------------------------------------------------------------------------
# Complete example — production e-commerce platform
# ---------------------------------------------------------------------------

module "dynamodb" {
  source = "../../"

  name_prefix = var.name_prefix
  tags        = var.tags

  # -------------------------------------------------------------------------
  # Standard Tables
  # -------------------------------------------------------------------------

  tables = {

    # -----------------------------------------------------------------------
    # users — login, session, profile data
    # -----------------------------------------------------------------------
    users = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key       = "user_id"
      hash_key_type  = "S"
      range_key      = null
      range_key_type = "S"

      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"

      ttl_attribute = "session_ttl"

      point_in_time_recovery = true
      deletion_protection    = true
      table_class            = "STANDARD"
      kms_key_arn            = var.kms_key_arn
      contributor_insights   = true
      backup_enabled         = true

      global_secondary_indexes = [
        {
          name            = "email-index"
          hash_key        = "email"
          hash_key_type   = "S"
          range_key       = null
          range_key_type  = "S"
          projection_type = "ALL"
        },
        {
          name            = "status-created-index"
          hash_key        = "status"
          hash_key_type   = "S"
          range_key       = "created_at"
          range_key_type  = "S"
          projection_type = "ALL"
        },
      ]

      local_secondary_indexes = []
      autoscaling             = null

      tags = {
        Service   = "user-service"
        DataClass = "PII"
      }
    }

    # -----------------------------------------------------------------------
    # orders — order lifecycle, history
    # -----------------------------------------------------------------------
    orders = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key       = "order_id"
      hash_key_type  = "S"
      range_key      = "created_at"
      range_key_type = "S"

      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"

      ttl_attribute = "archive_ttl"

      point_in_time_recovery = true
      deletion_protection    = true
      table_class            = "STANDARD"
      kms_key_arn            = var.kms_key_arn
      contributor_insights   = true
      backup_enabled         = true

      global_secondary_indexes = [
        {
          name            = "user-orders-index"
          hash_key        = "user_id"
          hash_key_type   = "S"
          range_key       = "created_at"
          range_key_type  = "S"
          projection_type = "ALL"
        },
        {
          name            = "status-index"
          hash_key        = "status"
          hash_key_type   = "S"
          range_key       = "updated_at"
          range_key_type  = "S"
          projection_type = "ALL"
        },
      ]

      local_secondary_indexes = [
        {
          name            = "orders-by-total"
          range_key       = "total_amount"
          range_key_type  = "N"
          projection_type = "ALL"
        },
      ]

      autoscaling = null

      tags = {
        Service = "order-service"
      }
    }

    # -----------------------------------------------------------------------
    # products — catalog, pricing
    # -----------------------------------------------------------------------
    products = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key       = "product_id"
      hash_key_type  = "S"
      range_key      = null
      range_key_type = "S"

      stream_enabled   = false
      stream_view_type = "NEW_AND_OLD_IMAGES"

      ttl_attribute = null

      point_in_time_recovery = true
      deletion_protection    = true
      table_class            = "STANDARD"
      kms_key_arn            = var.kms_key_arn
      contributor_insights   = false
      backup_enabled         = true

      global_secondary_indexes = [
        {
          name            = "category-price-index"
          hash_key        = "category"
          hash_key_type   = "S"
          range_key       = "price"
          range_key_type  = "N"
          projection_type = "ALL"
        },
      ]

      local_secondary_indexes = []
      autoscaling             = null

      tags = {
        Service = "catalog-service"
      }
    }

    # -----------------------------------------------------------------------
    # sessions — ephemeral, infrequently accessed once expired
    # -----------------------------------------------------------------------
    sessions = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key       = "session_id"
      hash_key_type  = "S"
      range_key      = null
      range_key_type = "S"

      stream_enabled   = false
      stream_view_type = "NEW_AND_OLD_IMAGES"

      ttl_attribute = "expires_at"

      point_in_time_recovery = false
      deletion_protection    = false
      table_class            = "STANDARD_INFREQUENT_ACCESS"
      kms_key_arn            = null
      contributor_insights   = false
      backup_enabled         = false

      global_secondary_indexes = []
      local_secondary_indexes  = []
      autoscaling              = null

      tags = {
        Service = "auth-service"
      }
    }

    # -----------------------------------------------------------------------
    # events — append-only event log, Kinesis CDC, TTL 7 days
    # -----------------------------------------------------------------------
    events = {
      billing_mode   = "PAY_PER_REQUEST"
      hash_key       = "event_id"
      hash_key_type  = "S"
      range_key      = "timestamp"
      range_key_type = "S"

      stream_enabled     = true
      stream_view_type   = "NEW_AND_OLD_IMAGES"
      kinesis_stream_arn = var.inventory_kinesis_stream_arn

      ttl_attribute = "expires_at"

      point_in_time_recovery = true
      deletion_protection    = false
      table_class            = "STANDARD"
      kms_key_arn            = null
      contributor_insights   = false
      backup_enabled         = true

      global_secondary_indexes = []
      local_secondary_indexes  = []
      autoscaling              = null

      tags = {
        Service = "event-service"
      }
    }

    # -----------------------------------------------------------------------
    # inventory — PROVISIONED with autoscaling (predictable high-traffic)
    # -----------------------------------------------------------------------
    inventory = {
      billing_mode   = "PROVISIONED"
      hash_key       = "product_id"
      hash_key_type  = "S"
      range_key      = "warehouse_id"
      range_key_type = "S"

      read_capacity  = 10
      write_capacity = 10

      stream_enabled   = false
      stream_view_type = "NEW_AND_OLD_IMAGES"

      ttl_attribute = null

      point_in_time_recovery = true
      deletion_protection    = true
      table_class            = "STANDARD"
      kms_key_arn            = var.kms_key_arn
      contributor_insights   = false
      backup_enabled         = true

      autoscaling = {
        min_read_capacity        = 5
        max_read_capacity        = 500
        min_write_capacity       = 5
        max_write_capacity       = 500
        target_read_utilization  = 70
        target_write_utilization = 70
      }

      global_secondary_indexes = [
        {
          name            = "warehouse-index"
          hash_key        = "warehouse_id"
          hash_key_type   = "S"
          range_key       = "product_id"
          range_key_type  = "S"
          projection_type = "ALL"
          read_capacity   = 5
          write_capacity  = 5
          autoscaling = {
            min_read_capacity        = 5
            max_read_capacity        = 200
            min_write_capacity       = 5
            max_write_capacity       = 200
            target_read_utilization  = 70
            target_write_utilization = 70
          }
        },
      ]

      local_secondary_indexes = []

      tags = {
        Service = "inventory-service"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Global Tables — orders replicated across 3 regions
  # -------------------------------------------------------------------------

  global_tables = {
    orders_global = {
      hash_key       = "order_id"
      hash_key_type  = "S"
      range_key      = "created_at"
      range_key_type = "S"

      stream_view_type       = "NEW_AND_OLD_IMAGES"
      kms_key_arn            = null
      point_in_time_recovery = true
      deletion_protection    = true

      global_secondary_indexes = [
        {
          name            = "user-orders-index"
          hash_key        = "user_id"
          hash_key_type   = "S"
          range_key       = "created_at"
          range_key_type  = "S"
          projection_type = "ALL"
        },
      ]

      replicas = [
        {
          region_name            = "eu-west-1"
          kms_key_arn            = null
          point_in_time_recovery = true
          propagate_tags         = true
        },
        {
          region_name            = "us-east-1"
          kms_key_arn            = null
          point_in_time_recovery = true
          propagate_tags         = true
        },
        {
          region_name            = "ap-southeast-1"
          kms_key_arn            = null
          point_in_time_recovery = true
          propagate_tags         = true
        },
      ]

      tags = {
        Service = "order-service"
        Global  = "true"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Alarms
  # -------------------------------------------------------------------------

  create_alarms        = true
  alarm_sns_topic_arn  = var.alarm_sns_topic_arn
  latency_threshold_ms = 100

  # -------------------------------------------------------------------------
  # Backup
  # -------------------------------------------------------------------------

  create_backup_plan         = true
  backup_secondary_vault_arn = var.backup_secondary_vault_arn

  # -------------------------------------------------------------------------
  # IAM
  # -------------------------------------------------------------------------

  create_iam_roles = true
}
