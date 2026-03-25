aws_region  = "us-east-1"
account_id  = "123456789012"
environment = "prod"

admin_role_arn    = "arn:aws:iam::123456789012:role/DataLakeAdmin"
analyst_role_arn  = "arn:aws:iam::123456789012:role/DataAnalyst"
engineer_role_arn = "arn:aws:iam::123456789012:role/DataEngineer"

tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Team        = "data-platform"
  CostCenter  = "engineering"
  Project     = "data-lakehouse"
}
