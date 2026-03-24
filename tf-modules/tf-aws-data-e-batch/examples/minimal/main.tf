# Minimal example — Fargate Spot compute environment, one job queue, one job definition.

module "batch" {
  source = "../../"

  create_iam_role = true

  compute_environments = {
    "fargate-spot-ce" = {
      type               = "MANAGED"
      compute_type       = "FARGATE_SPOT"
      max_vcpus          = 256
      subnet_ids         = ["subnet-0123456789abcdef0"]
      security_group_ids = ["sg-0123456789abcdef0"]
    }
  }

  job_queues = {
    "default-queue" = {
      priority                 = 10
      state                    = "ENABLED"
      compute_environment_keys = ["fargate-spot-ce"]
    }
  }

  job_definitions = {
    "simple-etl-job" = {
      type                  = "container"
      platform_capabilities = ["FARGATE"]
      image                 = "public.ecr.aws/amazonlinux/amazonlinux:2023"
      vcpus                 = 1
      memory                = 2048
      command               = ["python3", "/app/etl.py"]
      environment = {
        ENV         = "dev"
        OUTPUT_PATH = "s3://my-bucket/output/"
      }
      retry_attempts  = 2
      timeout_seconds = 1800
      propagate_tags  = true
    }
  }

  tags = {
    Project   = "data-platform"
    ManagedBy = "terraform"
  }
}
