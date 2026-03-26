# tests/unit/defaults.tftest.hcl
#
# Verifies default variable values and feature-gate behaviour.
# All runs use command = plan — no AWS resources are created.

provider "aws" {
  region = "us-east-1"

  # Allow plan to succeed without real credentials by using a mock / skip validation.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ── Test 1: create_lexicons defaults to false ───────────────────
# When create_lexicons is false (the default), no aws_polly_lexicon
# resources should appear in the plan, even if lexicons map is populated.
run "lexicons_disabled_by_default" {
  command = plan

  variables {
    # Explicitly confirm the default: no lexicons created
    create_lexicons = false
    lexicons = {
      my-lexicon = {
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
  }

  assert {
    condition     = length(aws_polly_lexicon.this) == 0
    error_message = "Expected zero lexicons when create_lexicons = false, but got ${length(aws_polly_lexicon.this)}."
  }
}

# ── Test 2: create_iam_role defaults to true ────────────────────
# With all defaults, one IAM role should be planned.
run "iam_role_created_by_default" {
  command = plan

  variables {
    # Accept all defaults (create_iam_role = true, create_lexicons = false)
  }

  assert {
    condition     = length(aws_iam_role.polly) == 1
    error_message = "Expected exactly 1 IAM role when create_iam_role = true (default), got ${length(aws_iam_role.polly)}."
  }
}

# ── Test 3: BYO role — no aws_iam_role planned ─────────────────
# When the caller supplies role_arn and sets create_iam_role = false,
# the module must NOT plan any aws_iam_role resource.
run "byo_role_skips_iam_resource" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/existing-polly-role"
  }

  assert {
    condition     = length(aws_iam_role.polly) == 0
    error_message = "Expected zero IAM roles when create_iam_role = false, got ${length(aws_iam_role.polly)}."
  }
}

# ── Test 4: BYO role ARN is surfaced in output ──────────────────
# local.role_arn (and therefore the iam_role_arn output) should equal
# the supplied role_arn when create_iam_role = false.
run "byo_role_arn_forwarded_to_output" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/existing-polly-role"
  }

  assert {
    condition     = output.iam_role_arn == "arn:aws:iam::123456789012:role/existing-polly-role"
    error_message = "iam_role_arn output did not match the supplied role_arn."
  }

  assert {
    condition     = output.iam_role_name == null
    error_message = "iam_role_name should be null when create_iam_role = false."
  }
}

# ── Test 5: name_prefix is optional (empty string is valid) ─────
run "empty_name_prefix_is_valid" {
  command = plan

  variables {
    name_prefix = ""
  }

  assert {
    condition     = length(aws_iam_role.polly) == 1
    error_message = "Module should plan successfully with an empty name_prefix."
  }
}
