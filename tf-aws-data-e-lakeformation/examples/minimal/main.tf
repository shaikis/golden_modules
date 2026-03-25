module "lakeformation" {
  source = "../../"

  data_lake_admins = ["arn:aws:iam::123456789012:role/DataLakeAdmin"]

  data_lake_locations = {
    raw = { s3_arn = "arn:aws:s3:::my-datalake-raw" }
  }
}
