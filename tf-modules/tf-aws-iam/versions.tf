terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Data sources used across all files
# ---------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
