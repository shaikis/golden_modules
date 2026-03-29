terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.5.0"
    }
  }
}

provider "aws" {
  alias   = "central"
  region  = var.central_region
  profile = var.central_profile
}

provider "aws" {
  alias   = "workload"
  region  = var.workload_region
  profile = var.workload_profile
}
