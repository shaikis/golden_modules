# ---------------------------------------------------------------------------
# Minimal Example — One SageMaker Studio Domain (IAM auth)
# ---------------------------------------------------------------------------

module "sagemaker" {
  source = "../.."

  # Only create an IAM role and a single Studio domain.
  create_iam_role = true

  domains = {
    "ml-studio-dev" = {
      auth_mode               = "IAM"
      vpc_id                  = "vpc-0abc123456789def0"
      subnet_ids              = ["subnet-0abc123456789def0", "subnet-0def123456789abc0"]
      app_network_access_type = "VpcOnly"
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
