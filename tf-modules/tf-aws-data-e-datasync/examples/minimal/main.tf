# ---------------------------------------------------------------------------
# Minimal Example — S3-to-S3 Sync Task (cross-account data copy)
# ---------------------------------------------------------------------------

module "datasync" {
  source = "../.."

  create_iam_role     = true
  create_s3_locations = true

  s3_bucket_arns_for_role = [
    "arn:aws:s3:::source-data-bucket",
    "arn:aws:s3:::destination-data-bucket",
  ]

  s3_locations = {
    "source-raw" = {
      s3_bucket_arn    = "arn:aws:s3:::source-data-bucket"
      subdirectory     = "/raw/"
      s3_storage_class = "STANDARD"
    }
    "destination-raw" = {
      s3_bucket_arn    = "arn:aws:s3:::destination-data-bucket"
      subdirectory     = "/raw/"
      s3_storage_class = "STANDARD"
    }
  }

  tasks = {
    "raw-cross-account-copy" = {
      source_location_key      = "source-raw"
      destination_location_key = "destination-raw"
      transfer_mode            = "CHANGED"
      verify_mode              = "ONLY_FILES_TRANSFERRED"
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
