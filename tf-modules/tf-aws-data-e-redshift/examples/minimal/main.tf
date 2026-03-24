module "redshift" {
  source = "../../"

  clusters = {
    analytics = {
      vpc_security_group_ids = ["sg-xxx"]
      subnet_group_key       = "analytics_sg"
    }
  }

  subnet_groups = {
    analytics_sg = {
      subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
