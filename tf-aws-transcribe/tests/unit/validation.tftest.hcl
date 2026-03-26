# ---------------------------------------------------------------------------
# Unit test: input validation rules
#
# Each run block deliberately supplies invalid input and expects Terraform's
# plan to fail with the appropriate validation error message.
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Vocabulary: neither phrases nor vocabulary_file_uri supplied
# ---------------------------------------------------------------------------
run "vocabulary_requires_phrases_or_file_uri" {
  command = plan

  variables {
    create_vocabularies = true
    vocabularies = {
      bad-vocab = {
        language_code = "en-US"
        # No phrases and no vocabulary_file_uri — must fail validation
      }
    }
  }

  expect_failures = [
    var.vocabularies,
  ]
}

# ---------------------------------------------------------------------------
# Vocabulary filter: neither words nor vocabulary_filter_file_uri supplied
# ---------------------------------------------------------------------------
run "vocabulary_filter_requires_words_or_file_uri" {
  command = plan

  variables {
    create_vocabulary_filters = true
    vocabulary_filters = {
      bad-filter = {
        language_code = "en-US"
        # No words and no vocabulary_filter_file_uri — must fail validation
      }
    }
  }

  expect_failures = [
    var.vocabulary_filters,
  ]
}

# ---------------------------------------------------------------------------
# Language model: invalid base_model_name
# ---------------------------------------------------------------------------
run "language_model_invalid_base_model_name" {
  command = plan

  variables {
    create_language_models = true
    language_models = {
      bad-model = {
        language_code   = "en-US"
        base_model_name = "SuperBand"   # invalid — must be NarrowBand or WideBand
        s3_uri          = "s3://my-bucket/training/"
      }
    }
  }

  expect_failures = [
    var.language_models,
  ]
}

# ---------------------------------------------------------------------------
# Language model: s3_uri not starting with s3://
# ---------------------------------------------------------------------------
run "language_model_invalid_s3_uri" {
  command = plan

  variables {
    create_language_models = true
    language_models = {
      bad-uri-model = {
        language_code   = "en-US"
        base_model_name = "WideBand"
        s3_uri          = "https://my-bucket/training/"  # invalid
      }
    }
  }

  expect_failures = [
    var.language_models,
  ]
}

# ---------------------------------------------------------------------------
# Medical vocabulary: language_code other than en-US
# ---------------------------------------------------------------------------
run "medical_vocabulary_invalid_language_code" {
  command = plan

  variables {
    create_medical_vocabularies = true
    medical_vocabularies = {
      bad-medical = {
        language_code       = "fr-FR"   # only en-US is supported
        vocabulary_file_uri = "s3://my-bucket/medical-terms.csv"
      }
    }
  }

  expect_failures = [
    var.medical_vocabularies,
  ]
}

# ---------------------------------------------------------------------------
# Medical vocabulary: vocabulary_file_uri not an S3 URI
# ---------------------------------------------------------------------------
run "medical_vocabulary_invalid_file_uri" {
  command = plan

  variables {
    create_medical_vocabularies = true
    medical_vocabularies = {
      bad-uri-medical = {
        language_code       = "en-US"
        vocabulary_file_uri = "https://example.com/terms.csv"  # invalid
      }
    }
  }

  expect_failures = [
    var.medical_vocabularies,
  ]
}

# ---------------------------------------------------------------------------
# BYO role_arn: malformed ARN
# ---------------------------------------------------------------------------
run "invalid_role_arn_rejected" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "not-a-valid-arn"
  }

  expect_failures = [
    var.role_arn,
  ]
}

# ---------------------------------------------------------------------------
# KMS key ARN: malformed ARN
# ---------------------------------------------------------------------------
run "invalid_kms_key_arn_rejected" {
  command = plan

  variables {
    kms_key_arn = "not-a-kms-arn"
  }

  expect_failures = [
    var.kms_key_arn,
  ]
}

# ---------------------------------------------------------------------------
# Valid configuration: passes all validations
# ---------------------------------------------------------------------------
run "valid_full_configuration_passes" {
  command = plan

  variables {
    name_prefix               = "prod"
    create_vocabularies       = true
    create_vocabulary_filters = true

    vocabularies = {
      call-center = {
        language_code = "en-US"
        phrases       = ["AWS", "EC2", "S3", "Lambda"]
        tags          = { UseCase = "call-center" }
      }
    }

    vocabulary_filters = {
      profanity = {
        language_code = "en-US"
        words         = ["badword1", "badword2"]
      }
    }

    tags = { Environment = "production" }
  }

  assert {
    condition     = length(aws_transcribe_vocabulary.this) == 1
    error_message = "Expected exactly one vocabulary to be planned."
  }

  assert {
    condition     = length(aws_transcribe_vocabulary_filter.this) == 1
    error_message = "Expected exactly one vocabulary filter to be planned."
  }
}
