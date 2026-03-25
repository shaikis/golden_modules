# Unit test — input validation for tf-aws-data-e-s3
# command = plan: no real AWS resources are created.
# These runs verify that invalid inputs are rejected before any apply.

run "valid_sse_algorithm_aes256_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    bucket_name   = "test-s3-aes256-123456"
    sse_algorithm = "AES256"
  }

  assert {
    condition     = var.sse_algorithm == "AES256"
    error_message = "AES256 is a valid sse_algorithm and must be accepted."
  }
}

run "valid_sse_algorithm_kms_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    bucket_name   = "test-s3-kms-123456"
    sse_algorithm = "aws:kms"
  }

  assert {
    condition     = var.sse_algorithm == "aws:kms"
    error_message = "aws:kms is a valid sse_algorithm and must be accepted."
  }
}

run "invalid_sse_algorithm_rejected" {
  command = plan
  expect_failures = [var.sse_algorithm]

  module {
    source = "../../"
  }

  variables {
    bucket_name   = "test-s3-bad-sse-123456"
    sse_algorithm = "NONE"
  }
}

run "valid_lifecycle_storage_class_glacier_accepted" {
  command = plan

  module {
    source = "../../"
  }

  variables {
    bucket_name = "test-s3-lifecycle-123456"

    lifecycle_rules = [
      {
        id      = "archive-rule"
        enabled = true
        transition = [
          {
            days          = 90
            storage_class = "GLACIER"
          }
        ]
      }
    ]
  }

  assert {
    condition     = length(var.lifecycle_rules) == 1
    error_message = "A lifecycle rule with GLACIER storage class must be accepted."
  }
}

# Placeholder: once a validation block is added for lifecycle transition
# storage_class values, uncomment to verify invalid values are rejected.
#
# run "invalid_lifecycle_storage_class_rejected" {
#   command = plan
#   expect_failures = [var.lifecycle_rules]
#
#   module {
#     source = "../../"
#   }
#
#   variables {
#     bucket_name = "test-s3-bad-lc-123456"
#     lifecycle_rules = [
#       {
#         id      = "bad-storage-class"
#         enabled = true
#         transition = [
#           {
#             days          = 30
#             storage_class = "MAGNETIC_TAPE"   # invalid
#           }
#         ]
#       }
#     ]
#   }
# }
