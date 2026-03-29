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

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
}

module "access_points" {
  source = "../.."

  bucket = aws_s3_bucket.example.id
  tags   = var.tags

  access_points = [
    {
      name = "${var.project}-shared"
      public_access_block_configuration = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    },
    {
      name   = "${var.project}-private"
      vpc_id = var.vpc_id
    }
  ]
}
