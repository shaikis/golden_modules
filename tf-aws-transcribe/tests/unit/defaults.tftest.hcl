# ---------------------------------------------------------------------------
# Unit test: default configuration
#
# Verifies that:
#  1. With all feature gates at their defaults (false), no transcribe resources
#     are planned.
#  2. create_iam_role = true (default) plans exactly one IAM role.
#  3. BYO role_arn works: create_iam_role = false + role_arn → no role created,
#     local.role_arn resolves to the supplied ARN.
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"

  # Skip real AWS calls during unit tests
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Run 1: Absolute minimum — nothing opted in, IAM role auto-created
# ---------------------------------------------------------------------------
run "defaults_no_resources_iam_created" {
  command = plan

  variables {
    # All feature gates default to false — explicit for clarity
    create_vocabularies         = false
    create_vocabulary_filters   = false
    create_language_models      = false
    create_medical_vocabularies = false
    # create_iam_role defaults to true
  }

  assert {
    condition     = length(aws_transcribe_vocabulary.this) == 0
    error_message = "Expected no vocabularies to be planned when create_vocabularies = false."
  }

  assert {
    condition     = length(aws_transcribe_vocabulary_filter.this) == 0
    error_message = "Expected no vocabulary filters to be planned when create_vocabulary_filters = false."
  }

  assert {
    condition     = length(aws_transcribe_language_model.this) == 0
    error_message = "Expected no language models to be planned when create_language_models = false."
  }

  assert {
    condition     = length(aws_transcribe_medical_vocabulary.this) == 0
    error_message = "Expected no medical vocabularies to be planned when create_medical_vocabularies = false."
  }

  assert {
    condition     = length(aws_iam_role.transcribe) == 1
    error_message = "Expected exactly one IAM role to be planned when create_iam_role = true (default)."
  }
}

# ---------------------------------------------------------------------------
# Run 2: BYO role — create_iam_role = false, role_arn supplied
# ---------------------------------------------------------------------------
run "byo_role_no_iam_created" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/my-existing-transcribe-role"
  }

  assert {
    condition     = length(aws_iam_role.transcribe) == 0
    error_message = "Expected no IAM role to be planned when create_iam_role = false."
  }

  assert {
    condition     = output.iam_role_arn == "arn:aws:iam::123456789012:role/my-existing-transcribe-role"
    error_message = "iam_role_arn output should reflect the BYO role_arn when create_iam_role = false."
  }
}

# ---------------------------------------------------------------------------
# Run 3: name_prefix propagation
# ---------------------------------------------------------------------------
run "name_prefix_is_applied" {
  command = plan

  variables {
    name_prefix             = "myapp"
    create_vocabularies     = true
    vocabularies = {
      greetings = {
        language_code = "en-US"
        phrases       = ["hello", "goodbye"]
      }
    }
  }

  assert {
    condition     = aws_transcribe_vocabulary.this["greetings"].vocabulary_name == "myapp-greetings"
    error_message = "Vocabulary name should be prefixed with 'myapp-'."
  }
}

# ---------------------------------------------------------------------------
# Run 4: tags merged correctly
# ---------------------------------------------------------------------------
run "tags_merged" {
  command = plan

  variables {
    tags = { Environment = "test", Team = "data" }
    create_vocabularies = true
    vocabularies = {
      sample = {
        language_code = "en-US"
        phrases       = ["aws", "transcribe"]
      }
    }
  }

  assert {
    condition     = aws_transcribe_vocabulary.this["sample"].tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy=terraform tag from module locals."
  }

  assert {
    condition     = aws_transcribe_vocabulary.this["sample"].tags["Module"] == "tf-aws-transcribe"
    error_message = "Expected Module=tf-aws-transcribe tag from module locals."
  }

  assert {
    condition     = aws_transcribe_vocabulary.this["sample"].tags["Environment"] == "test"
    error_message = "Expected caller-supplied Environment=test tag to be present."
  }
}
