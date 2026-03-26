# tests/integration/basic.tftest.hcl
# SKIP_IN_CI
#
# Integration test — creates real AWS resources.
# Requires valid AWS credentials and appropriate IAM permissions.
#
# Resources created (all free-tier / no ongoing cost):
#   - 1 x aws_polly_lexicon   (Polly lexicons are free)
#   - 1 x aws_iam_role        (IAM roles are free)
#   - 1 x aws_iam_role_policy (IAM policies are free)
#
# Run with:
#   terraform test -filter=tests/integration/basic.tftest.hcl
#
# Environment variables:
#   AWS_REGION  (default: us-east-1)
#   AWS_PROFILE or AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

provider "aws" {
  region = "us-east-1"
}

# ── Test: create one lexicon and verify outputs ─────────────────
run "create_single_lexicon" {
  command = apply

  variables {
    name_prefix     = "tftest"
    create_lexicons = true
    create_iam_role = true

    lexicons = {
      w3c-terms = {
        content = <<-PLS
          <?xml version="1.0" encoding="UTF-8"?>
          <lexicon version="1.0"
            xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
            alphabet="ipa"
            xml:lang="en-US">
            <lexeme><grapheme>W3C</grapheme><alias>World Wide Web Consortium</alias></lexeme>
          </lexicon>
        PLS
      }
    }

    tags = {
      Environment = "ci"
      ManagedBy   = "terraform-test"
    }
  }

  # Verify lexicon_names output has exactly 1 entry
  assert {
    condition     = length(output.lexicon_names) == 1
    error_message = "Expected 1 entry in lexicon_names output, got ${length(output.lexicon_names)}."
  }

  # Verify the key matches what we supplied
  assert {
    condition     = contains(keys(output.lexicon_names), "w3c-terms")
    error_message = "Expected 'w3c-terms' key in lexicon_names output."
  }

  # Verify the name value matches the key (Polly uses the name as provided)
  assert {
    condition     = output.lexicon_names["w3c-terms"] == "w3c-terms"
    error_message = "Expected lexicon name to be 'w3c-terms', got '${output.lexicon_names["w3c-terms"]}'."
  }

  # Verify lexicon_arns output has exactly 1 entry
  assert {
    condition     = length(output.lexicon_arns) == 1
    error_message = "Expected 1 entry in lexicon_arns output, got ${length(output.lexicon_arns)}."
  }

  # Verify the ARN is non-empty
  assert {
    condition     = output.lexicon_arns["w3c-terms"] != ""
    error_message = "Expected a non-empty ARN for 'w3c-terms' lexicon."
  }

  # Verify IAM role was created and ARN is returned
  assert {
    condition     = output.iam_role_arn != null && output.iam_role_arn != ""
    error_message = "Expected a non-null, non-empty iam_role_arn output."
  }

  assert {
    condition     = output.iam_role_name == "tftest-polly-role"
    error_message = "Expected iam_role_name to be 'tftest-polly-role', got '${output.iam_role_name}'."
  }
}
