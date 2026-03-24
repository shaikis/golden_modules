module "mwaa" {
  source = "../../"

  name_prefix = "minimal-"

  environments = {
    data_platform = {
      source_bucket_arn  = "arn:aws:s3:::my-mwaa-bucket"
      subnet_ids         = ["subnet-private-a", "subnet-private-b"]
      security_group_ids = ["sg-mwaa"]
    }
  }
}
