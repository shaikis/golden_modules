terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ── Provider configuration ────────────────────────────────────────────────────
# Route 53 is a global service — any region works for the provider.
# The eu-west-3 alias is used to create CloudWatch alarms in Paris (for RDS).
# The eu-central-1 alias is used to create CloudWatch alarms in Frankfurt (for replica).

provider "aws" {
  region = "eu-west-3" # Paris — primary region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Module      = "tf-aws-route53"
      Scenario    = "rds-alb-paris-frankfurt"
      Environment = "prod"
    }
  }
}

provider "aws" {
  alias  = "paris"
  region = "eu-west-3"
}

provider "aws" {
  alias  = "frankfurt"
  region = "eu-central-1"
}
