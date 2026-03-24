# ---------------------------------------------------------------------------
# Global Table example — multi-region active-active DynamoDB
#
# Architecture:
#   us-east-1 (primary write) ←→ eu-west-1 ←→ ap-southeast-1
#
# Both tables use PAY_PER_REQUEST billing (required for Global Tables v2).
# Streams are always enabled (required for Global Tables).
# ---------------------------------------------------------------------------

module "dynamodb_global" {
  source = "../../"

  name_prefix = var.name_prefix
  tags        = var.tags

  tables = {}

  global_tables = {

    # -----------------------------------------------------------------------
    # user_profiles — global user data replicated to 3 regions
    # -----------------------------------------------------------------------
    user_profiles = {
      hash_key       = "user_id"
      hash_key_type  = "S"
      range_key      = null
      range_key_type = "S"

      stream_view_type       = "NEW_AND_OLD_IMAGES"
      kms_key_arn            = null # AWS-owned key per region
      point_in_time_recovery = true
      deletion_protection    = true

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
          name            = "region-status-index"
          hash_key        = "home_region"
          hash_key_type   = "S"
          range_key       = "account_status"
          range_key_type  = "S"
          projection_type = "KEYS_ONLY"
        },
      ]

      # Replicas in eu-west-1 and ap-southeast-1
      # us-east-1 is the primary (managed by the main provider)
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
        Service   = "identity-service"
        DataClass = "PII"
      }
    }

    # -----------------------------------------------------------------------
    # sessions_global — stateless session tokens for active-active auth
    # -----------------------------------------------------------------------
    sessions_global = {
      hash_key       = "session_id"
      hash_key_type  = "S"
      range_key      = null
      range_key_type = "S"

      stream_view_type       = "NEW_AND_OLD_IMAGES"
      kms_key_arn            = null
      point_in_time_recovery = false # Sessions are ephemeral; PITR not needed
      deletion_protection    = true

      global_secondary_indexes = [
        {
          name            = "user-sessions-index"
          hash_key        = "user_id"
          hash_key_type   = "S"
          range_key       = "created_at"
          range_key_type  = "S"
          projection_type = "INCLUDE"
          non_key_attributes = [
            "expires_at",
            "device_id",
            "ip_address",
          ]
        },
      ]

      replicas = [
        {
          region_name            = "eu-west-1"
          kms_key_arn            = null
          point_in_time_recovery = false
          propagate_tags         = true
        },
        {
          region_name            = "us-east-1"
          kms_key_arn            = null
          point_in_time_recovery = false
          propagate_tags         = true
        },
        {
          region_name            = "ap-southeast-1"
          kms_key_arn            = null
          point_in_time_recovery = false
          propagate_tags         = true
        },
      ]

      tags = {
        Service = "auth-service"
        TTL     = "enabled"
      }
    }
  }

  # Replication latency alarm
  create_alarms                    = true
  alarm_sns_topic_arn              = var.alarm_sns_topic_arn
  replication_latency_threshold_ms = 500

  # No backup plan needed — replicas provide HA; PITR handles recovery
  create_backup_plan = false

  create_iam_roles = true
}
