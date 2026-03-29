terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "reports" {
  bucket = var.reports_bucket_name
}

module "storage_lens" {
  source = "../.."

  config_id = var.config_id
  tags      = var.tags

  account_level = {
    activity_metrics                   = true
    advanced_cost_optimization_metrics = true
    bucket_level = {
      activity_metrics                   = true
      advanced_cost_optimization_metrics = true
      prefix_level = {
        storage_metrics = {
          enabled = true
          selection_criteria = {
            delimiter                    = "/"
            max_depth                    = 5
            min_storage_bytes_percentage = 1
          }
        }
      }
    }
  }

  include = {
    regions = [var.aws_region]
  }

  data_export = {
    cloud_watch_metrics_enabled = true
    s3_bucket_destination = {
      arn                   = aws_s3_bucket.reports.arn
      format                = "CSV"
      output_schema_version = "V_1"
      prefix                = "storage-lens/"
      encryption = {
        type = "SSE-S3"
      }
    }
  }
}
