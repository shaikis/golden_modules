# =============================================================================
# Example: AppConfig Feature Flags for SaaS Microservices
# =============================================================================
# Real-world pattern: SaaS company releases features to 10% of prod users first,
# monitors error rates, then gradually rolls out to 100%.
# Zero redeployments — just update the hosted config and deploy.
#
# Relevant to: Innovation Sandbox on AWS blog
# https://aws.amazon.com/blogs/mt/innovation-sandbox-on-aws-with-real-time-analytics-dashboard/
# (Uses AppConfig for sandbox budget thresholds and allowed services per team)
# =============================================================================

module "ssm_appconfig" {
  source      = "../../"
  name        = "mysaas"
  environment = "prod"

  enable_appconfig           = true
  appconfig_application_name = "mysaas-platform"
  appconfig_description      = "Feature flags and configuration for MySaaS Platform"

  # ---------------------------------------------------------------------------
  # ENVIRONMENTS
  # dev → staging → prod, each with independent flag values
  # ---------------------------------------------------------------------------
  appconfig_environments = {
    "dev" = {
      description = "Development — feature flags visible to internal engineers only"
      monitors    = [] # No alarms in dev — fail fast, learn fast
    }

    "staging" = {
      description = "Staging — feature flags for QA team and beta program users"
      monitors    = [] # No auto-rollback in staging — manual review
    }

    "prod" = {
      description = "Production — feature flags with CloudWatch alarm monitoring and auto-rollback"
      monitors = [
        {
          # If API error rate spikes during a deployment, AppConfig automatically
          # rolls back to the previous configuration version.
          alarm_arn      = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:mysaas-prod-api-error-rate"
          alarm_role_arn = "arn:aws:iam::123456789012:role/AppConfigCloudWatchRole"
        }
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # CONFIGURATION PROFILES
  # ---------------------------------------------------------------------------
  appconfig_configuration_profiles = {

    # Feature flags — AppConfig native type with rich UI in AWS Console
    # Engineers can toggle flags without touching Terraform
    "feature-flags" = {
      type         = "AWS.AppConfig.FeatureFlags"
      description  = "Boolean and percentage-based feature flags for all microservices"
      location_uri = "hosted"
      validators   = [] # AppConfig validates the schema automatically for FeatureFlags type
    }

    # Platform settings — free-form JSON with JSON Schema validation
    # Prevents misconfiguration from reaching production
    "platform-settings" = {
      type         = "AWS.Freeform"
      description  = "Platform-wide settings: rate limits, timeouts, upload quotas"
      location_uri = "hosted"
      validators = [
        {
          type = "JSON_SCHEMA"
          content = jsonencode({
            "$schema" = "http://json-schema.org/draft-07/schema#"
            type      = "object"
            properties = {
              rate_limit_rpm = {
                type        = "integer"
                minimum     = 100
                maximum     = 10000
                description = "API rate limit in requests per minute per authenticated user"
              }
              max_file_size_mb = {
                type        = "integer"
                minimum     = 1
                maximum     = 100
                description = "Maximum file upload size in megabytes"
              }
              maintenance_mode = {
                type        = "boolean"
                description = "When true, all non-admin requests receive HTTP 503"
              }
              allowed_regions = {
                type  = "array"
                items = { type = "string" }
                description = "ISO country codes where service is available"
              }
              session_timeout_minutes = {
                type    = "integer"
                minimum = 15
                maximum = 1440
              }
            }
            required             = ["rate_limit_rpm", "maintenance_mode"]
            additionalProperties = false
          })
        }
      ]
    }

    # Innovation sandbox config: controls which AWS services each hackathon team
    # can provision and their budget ceiling. Matches the Innovation Sandbox blog.
    "sandbox-config" = {
      type         = "AWS.Freeform"
      description  = "Innovation sandbox: per-team budget limits and allowed AWS service list"
      location_uri = "hosted"
      validators = [
        {
          type = "JSON_SCHEMA"
          content = jsonencode({
            "$schema" = "http://json-schema.org/draft-07/schema#"
            type      = "object"
            properties = {
              default_budget_usd = {
                type    = "number"
                minimum = 0
                maximum = 10000
              }
              allowed_services = {
                type  = "array"
                items = { type = "string" }
              }
              auto_terminate_after_days = {
                type    = "integer"
                minimum = 1
                maximum = 90
              }
              notify_at_percent = {
                type    = "integer"
                minimum = 10
                maximum = 90
              }
            }
            required = ["default_budget_usd", "allowed_services"]
          })
        }
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # DEPLOYMENT STRATEGY
  # LINEAR rollout: 10% every 3 minutes = 30 minutes total
  # Then a 10-minute bake time at 100% before marking deployment "complete"
  # If a CloudWatch alarm fires during deployment OR bake time: auto-rollback
  # ---------------------------------------------------------------------------
  appconfig_deployment_strategy = {
    name                           = "gradual-prod-rollout"
    deployment_duration_in_minutes = 30  # Total rollout: 10 steps x 3 min
    growth_factor                  = 10  # Increment size: 10% per step
    final_bake_time_in_minutes     = 10  # Monitor at 100% for 10 min before completing
    growth_type                    = "LINEAR"
    replicate_to                   = "NONE"
    description                    = "Gradual 30-min linear rollout with 10-min bake and CW alarm auto-rollback"
  }

  tags = {
    Team       = "platform"
    CostCenter = "product"
  }
}

# ---------------------------------------------------------------------------
# Example: hosted configuration content for the feature-flags profile
# In practice, create these via AWS Console or aws appconfig create-hosted-configuration-version
# ---------------------------------------------------------------------------
#
# resource "aws_appconfig_hosted_configuration_version" "feature_flags_prod" {
#   application_id           = module.ssm_appconfig.appconfig_application_id
#   configuration_profile_id = module.ssm_appconfig.appconfig_configuration_profile_ids["feature-flags"]
#   content_type             = "application/json"
#
#   content = jsonencode({
#     flags = {
#       new_dashboard = {
#         name        = "New Dashboard UI"
#         description = "Redesigned analytics dashboard — gradual rollout"
#         _createdAt  = "2025-01-15T10:00:00Z"
#       }
#       bulk_export = {
#         name        = "Bulk Data Export"
#         description = "Allow users to export up to 1M rows as CSV"
#         _createdAt  = "2025-02-01T09:00:00Z"
#       }
#       ai_suggestions = {
#         name        = "AI-Powered Suggestions"
#         description = "Show ML-generated recommendations in sidebar"
#         _createdAt  = "2025-03-10T14:00:00Z"
#       }
#     }
#     values = {
#       new_dashboard  = { enabled = true }
#       bulk_export    = { enabled = false }  # Still in beta
#       ai_suggestions = { enabled = true }
#     }
#     version = "1"
#   })
# }
#
# resource "aws_appconfig_deployment" "feature_flags_prod" {
#   application_id           = module.ssm_appconfig.appconfig_application_id
#   configuration_profile_id = module.ssm_appconfig.appconfig_configuration_profile_ids["feature-flags"]
#   configuration_version    = aws_appconfig_hosted_configuration_version.feature_flags_prod.version_number
#   deployment_strategy_id   = module.ssm_appconfig.appconfig_deployment_strategy_id
#   environment_id           = module.ssm_appconfig.appconfig_environment_ids["prod"]
#   description              = "Enable new dashboard for all prod users"
# }

# ---------------------------------------------------------------------------
# OUTPUTS — pass these to ECS task definitions / Lambda environment variables
# ---------------------------------------------------------------------------
output "appconfig_application_id" {
  description = "Set as APPCONFIG_APP_ID environment variable in ECS tasks and Lambda functions"
  value       = module.ssm_appconfig.appconfig_application_id
}

output "appconfig_environment_ids" {
  description = "Map of environment name -> environment ID. Set APPCONFIG_ENV_ID per deployment stage."
  value       = module.ssm_appconfig.appconfig_environment_ids
}

output "appconfig_profile_ids" {
  description = "Map of profile name -> profile ID. Set APPCONFIG_PROFILE_ID per service/use-case."
  value       = module.ssm_appconfig.appconfig_configuration_profile_ids
}

output "appconfig_deployment_strategy_id" {
  description = "Deployment strategy ID — reference this when triggering deployments via CI/CD"
  value       = module.ssm_appconfig.appconfig_deployment_strategy_id
}
