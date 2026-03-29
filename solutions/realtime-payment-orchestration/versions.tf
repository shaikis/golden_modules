terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  # Recommended: use S3 + DynamoDB remote state with locking
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "payments/realtime-orchestration/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "tfstate-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.primary_region
  default_tags {
    tags = {
      Solution    = "realtime-payment-orchestration"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# CloudFront WAF MUST be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Solution    = "realtime-payment-orchestration"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
