# ---------------------------------------------------------------------------
# Integration test: basic vocabulary creation
#
# SKIP_IN_CI — requires real AWS credentials and an active AWS account.
#
# What this tests:
#  - Creating a single custom vocabulary using a phrases list (no S3 file)
#  - The vocabulary_arns output is populated after apply
#  - The vocabulary is accessible and the name matches what was requested
#  - Proper cleanup on destroy
#
# Prerequisites:
#  - AWS credentials configured (env vars, ~/.aws/credentials, or IAM role)
#  - Region accessible: us-east-1 (or override TF_VAR_region)
#  - aws_transcribe_vocabulary is available in the target region
#
# Run manually:
#   terraform test -filter=tests/integration/basic.tftest.hcl
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Run 1: Create one vocabulary with a phrases list — apply + assert + destroy
# ---------------------------------------------------------------------------
run "create_vocabulary_with_phrases" {
  command = apply

  variables {
    name_prefix         = "tftest"
    create_vocabularies = true

    vocabularies = {
      it-terms = {
        language_code = "en-US"
        phrases = [
          "Amazon Web Services",
          "EC2",
          "S3",
          "Lambda",
          "Terraform",
          "Kubernetes",
          "CloudFormation",
        ]
        tags = { TestRun = "integration-basic" }
      }
    }

    tags = { Environment = "ci", ManagedBy = "terraform-test" }
  }

  # The vocabulary ARN map must contain the key we created
  assert {
    condition     = length(output.vocabulary_arns) == 1
    error_message = "Expected exactly one vocabulary ARN in the output map."
  }

  assert {
    condition     = contains(keys(output.vocabulary_arns), "it-terms")
    error_message = "vocabulary_arns map should contain key 'it-terms'."
  }

  assert {
    condition     = can(regex("^arn:", output.vocabulary_arns["it-terms"]))
    error_message = "vocabulary_arns['it-terms'] should be a valid ARN."
  }

  # vocabulary_names list should contain the prefixed name
  assert {
    condition     = contains(output.vocabulary_names, "tftest-it-terms")
    error_message = "vocabulary_names should include 'tftest-it-terms' (name_prefix applied)."
  }

  # IAM role should have been auto-created
  assert {
    condition     = output.iam_role_arn != ""
    error_message = "iam_role_arn should be non-empty when create_iam_role = true."
  }

  assert {
    condition     = can(regex("^arn:.*:iam::", output.iam_role_arn))
    error_message = "iam_role_arn should be a valid IAM ARN."
  }
}

# ---------------------------------------------------------------------------
# Run 2: BYO role — no new IAM role created, vocabulary still works
#         (re-uses the ARN produced by run 1's auto-created role)
# ---------------------------------------------------------------------------
run "create_vocabulary_byo_role" {
  command = apply

  variables {
    name_prefix         = "tftest-byo"
    create_vocabularies = true
    create_iam_role     = false
    role_arn            = run.create_vocabulary_with_phrases.iam_role_arn

    vocabularies = {
      support-terms = {
        language_code = "en-US"
        phrases       = ["ticket", "escalation", "SLA", "MTTR", "incident"]
      }
    }
  }

  assert {
    condition     = length(output.vocabulary_arns) == 1
    error_message = "Expected exactly one vocabulary ARN for BYO role run."
  }

  assert {
    condition     = output.iam_role_arn == run.create_vocabulary_with_phrases.iam_role_arn
    error_message = "iam_role_arn should equal the BYO role ARN passed in."
  }
}

# ---------------------------------------------------------------------------
# Run 3: Vocabulary filter creation
# ---------------------------------------------------------------------------
run "create_vocabulary_filter" {
  command = apply

  variables {
    name_prefix               = "tftest"
    create_vocabulary_filters = true

    vocabulary_filters = {
      banned-words = {
        language_code = "en-US"
        words         = ["spam", "junk", "garbage"]
        tags          = { TestRun = "integration-basic" }
      }
    }
  }

  assert {
    condition     = length(output.vocabulary_filter_arns) == 1
    error_message = "Expected exactly one vocabulary filter ARN in the output map."
  }

  assert {
    condition     = contains(keys(output.vocabulary_filter_arns), "banned-words")
    error_message = "vocabulary_filter_arns should contain key 'banned-words'."
  }
}
