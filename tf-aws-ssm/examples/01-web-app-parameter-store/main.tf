# =============================================================================
# Example: Three-Tier Web Application — SSM Parameter Store
# =============================================================================
# Real-world pattern: fintech app stores ALL config in SSM Parameter Store.
# ECS tasks read parameters at startup via IAM role (no hardcoded secrets).
#
# Naming convention: /<environment>/<app>/<component>/<param>
# Tier:  Standard  = free, max 4KB, 10,000 params
#        Advanced  = $0.05/param/month, max 8KB, 100,000 params, TTL expiry
# Type:  String         = plaintext config (endpoints, ports, names)
#        SecureString   = encrypted with KMS (passwords, API keys, tokens)
#        StringList     = comma-separated list (allowed CIDRs, feature list)
# =============================================================================

module "ssm_web_app" {
  source      = "../../"
  name        = "fintech-app"
  environment = "prod"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123" # Replace with real KMS key

  # ---------------------------------------------------------------------------
  # DATABASE PARAMETERS (RDS Aurora PostgreSQL)
  # ---------------------------------------------------------------------------
  parameters = {

    # -- Connection details (String — not secret) ------------------------------
    "/prod/fintech-app/database/host" = {
      value       = "fintech-prod.cluster-abc123.us-east-1.rds.amazonaws.com"
      type        = "String"
      description = "RDS Aurora cluster writer endpoint"
      tier        = "Standard"
    }

    "/prod/fintech-app/database/reader_host" = {
      value       = "fintech-prod.cluster-ro-abc123.us-east-1.rds.amazonaws.com"
      type        = "String"
      description = "RDS Aurora cluster reader endpoint for read replicas"
    }

    "/prod/fintech-app/database/port" = {
      value           = "5432"
      type            = "String"
      description     = "PostgreSQL port"
      allowed_pattern = "^[0-9]{4,5}$"
    }

    "/prod/fintech-app/database/name" = {
      value       = "fintechdb"
      type        = "String"
      description = "Database name"
    }

    "/prod/fintech-app/database/username" = {
      value       = "app_user"
      type        = "String"
      description = "Application database username (non-admin)"
    }

    # -- Credentials (SecureString — encrypted with KMS) ----------------------
    "/prod/fintech-app/database/password" = {
      value       = "CHANGE_ME_ROTATE_VIA_SECRETS_MANAGER"
      type        = "SecureString"
      description = "RDS master password — rotated every 90 days via Lambda"
      tier        = "Standard"
    }

    "/prod/fintech-app/database/connection_string" = {
      value       = "postgresql://app_user:PLACEHOLDER@fintech-prod.cluster-abc123.us-east-1.rds.amazonaws.com:5432/fintechdb?sslmode=require"
      type        = "SecureString"
      description = "Full PostgreSQL connection string — used by ECS task directly"
    }

    # -- Pool settings --------------------------------------------------------
    "/prod/fintech-app/database/pool_min" = {
      value       = "5"
      type        = "String"
      description = "Minimum DB connection pool size per ECS task"
    }

    "/prod/fintech-app/database/pool_max" = {
      value       = "20"
      type        = "String"
      description = "Maximum DB connection pool size per ECS task"
    }

    # ---------------------------------------------------------------------------
    # THIRD-PARTY API KEYS (SecureString)
    # ---------------------------------------------------------------------------
    "/prod/fintech-app/stripe/secret_key" = {
      value       = "sk_live_REPLACE_WITH_REAL_KEY"
      type        = "SecureString"
      description = "Stripe live secret key — used by payment service ECS task"
      tier        = "Standard"
    }

    "/prod/fintech-app/stripe/webhook_secret" = {
      value       = "whsec_REPLACE_WITH_REAL_SECRET"
      type        = "SecureString"
      description = "Stripe webhook signing secret — validates incoming Stripe events"
    }

    "/prod/fintech-app/sendgrid/api_key" = {
      value       = "SG.REPLACE_WITH_REAL_KEY"
      type        = "SecureString"
      description = "SendGrid API key for transactional email (receipts, alerts)"
    }

    "/prod/fintech-app/twilio/account_sid" = {
      value       = "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      type        = "String"
      description = "Twilio Account SID (not secret)"
    }

    "/prod/fintech-app/twilio/auth_token" = {
      value       = "REPLACE_WITH_REAL_TOKEN"
      type        = "SecureString"
      description = "Twilio Auth Token for SMS OTP"
    }

    # ---------------------------------------------------------------------------
    # APPLICATION CONFIGURATION (String / StringList)
    # ---------------------------------------------------------------------------
    "/prod/fintech-app/app/jwt_secret" = {
      value       = "REPLACE_WITH_256BIT_RANDOM_SECRET"
      type        = "SecureString"
      description = "JWT signing secret — rotate every 180 days"
    }

    "/prod/fintech-app/app/jwt_expiry_minutes" = {
      value       = "60"
      type        = "String"
      description = "JWT token expiry in minutes"
    }

    "/prod/fintech-app/app/cors_allowed_origins" = {
      value       = "https://app.fintech.com,https://admin.fintech.com"
      type        = "StringList"
      description = "CORS allowed origins — comma separated"
    }

    "/prod/fintech-app/app/rate_limit_rpm" = {
      value       = "1000"
      type        = "String"
      description = "API rate limit in requests per minute per user"
    }

    "/prod/fintech-app/app/log_level" = {
      value           = "INFO"
      type            = "String"
      description     = "Application log level: DEBUG | INFO | WARN | ERROR"
      allowed_pattern = "^(DEBUG|INFO|WARN|ERROR)$"
    }

    "/prod/fintech-app/app/feature_dark_mode" = {
      value           = "true"
      type            = "String"
      description     = "Feature flag: enable dark mode UI"
      allowed_pattern = "^(true|false)$"
    }

    "/prod/fintech-app/app/maintenance_mode" = {
      value           = "false"
      type            = "String"
      description     = "Set to true to show maintenance page to all users"
      allowed_pattern = "^(true|false)$"
    }

    # ---------------------------------------------------------------------------
    # INFRASTRUCTURE REFERENCES (String)
    # ---------------------------------------------------------------------------
    "/prod/fintech-app/infra/s3_uploads_bucket" = {
      value       = "fintech-prod-user-uploads"
      type        = "String"
      description = "S3 bucket for user document uploads"
    }

    "/prod/fintech-app/infra/s3_reports_bucket" = {
      value       = "fintech-prod-reports"
      type        = "String"
      description = "S3 bucket for generated financial reports"
    }

    "/prod/fintech-app/infra/sqs_payment_queue_url" = {
      value       = "https://sqs.us-east-1.amazonaws.com/123456789012/fintech-prod-payments.fifo"
      type        = "String"
      description = "SQS FIFO queue URL for payment processing"
    }

    "/prod/fintech-app/infra/redis_host" = {
      value       = "fintech-prod.abc123.ng.0001.use1.cache.amazonaws.com"
      type        = "String"
      description = "ElastiCache Redis primary endpoint for session + rate-limit cache"
    }

    "/prod/fintech-app/infra/redis_port" = {
      value = "6379"
      type  = "String"
    }

    # ---------------------------------------------------------------------------
    # AMI REFERENCE (String with data_type = aws:ec2:image)
    # SSM validates this is a real, existing AMI ID
    # ---------------------------------------------------------------------------
    "/prod/fintech-app/infra/golden_ami_id" = {
      value       = "ami-0abcdef1234567890"
      type        = "String"
      data_type   = "aws:ec2:image"
      description = "Hardened golden AMI — updated monthly by image pipeline"
      tier        = "Standard"
    }

    # ---------------------------------------------------------------------------
    # CROSS-ACCOUNT / SHARED PARAMETERS (Advanced tier — for sharing)
    # ---------------------------------------------------------------------------
    "/prod/fintech-app/shared/vpc_id" = {
      value       = "vpc-0abc123def456789"
      type        = "String"
      description = "Shared VPC ID — used by all services in prod account"
      tier        = "Advanced" # Advanced tier required for cross-account sharing
    }

    "/prod/fintech-app/shared/private_subnet_ids" = {
      value       = "subnet-0111aaa,subnet-0222bbb,subnet-0333ccc"
      type        = "StringList"
      description = "Private subnet IDs across all 3 AZs"
      tier        = "Advanced"
    }
  }
}

# =============================================================================
# How ECS tasks read these parameters at runtime:
# =============================================================================
#
# In your ECS task definition:
#   secrets = [
#     { name = "DB_PASSWORD", valueFrom = "/prod/fintech-app/database/password" }
#     { name = "STRIPE_KEY",  valueFrom = "/prod/fintech-app/stripe/secret_key"  }
#   ]
#   environment = [
#     { name = "DB_HOST", value = "/prod/fintech-app/database/host" }
#   ]
#
# ECS task IAM role needs:
#   ssm:GetParameters on arn:aws:ssm:*:*:parameter/prod/fintech-app/*
#   kms:Decrypt        on your KMS key ARN
# =============================================================================

output "all_parameter_arns" {
  value = module.ssm_web_app.parameter_arns
}

output "all_parameter_names" {
  value = module.ssm_web_app.parameter_names
}
