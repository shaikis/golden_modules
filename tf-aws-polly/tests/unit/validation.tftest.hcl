# tests/unit/validation.tftest.hcl
#
# Validates input combinations and edge cases.
# All runs use command = plan — no AWS resources are created.

provider "aws" {
  region = "us-east-1"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ── Test 1: lexicons map requires the content field ─────────────
# The object type constraint on var.lexicons enforces that each entry
# supplies a `content` string. A plan with a well-formed entry succeeds.
run "lexicons_with_valid_content_field" {
  command = plan

  variables {
    create_lexicons = true
    lexicons = {
      valid-lexicon = {
        content = <<-PLS
          <?xml version="1.0" encoding="UTF-8"?>
          <lexicon version="1.0"
            xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
            alphabet="ipa"
            xml:lang="en-US">
            <lexeme><grapheme>TF</grapheme><alias>Terraform</alias></lexeme>
          </lexicon>
        PLS
      }
    }
  }

  assert {
    condition     = length(aws_polly_lexicon.this) == 1
    error_message = "Expected exactly 1 lexicon planned, got ${length(aws_polly_lexicon.this)}."
  }
}

# ── Test 2: multiple lexicons planned correctly ─────────────────
run "multiple_lexicons_planned" {
  command = plan

  variables {
    create_lexicons = true
    lexicons = {
      tech-terms = {
        content = <<-PLS
          <?xml version="1.0" encoding="UTF-8"?>
          <lexicon version="1.0"
            xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
            alphabet="ipa" xml:lang="en-US">
            <lexeme><grapheme>API</grapheme><alias>Application Programming Interface</alias></lexeme>
          </lexicon>
        PLS
      }
      brand-names = {
        content = <<-PLS
          <?xml version="1.0" encoding="UTF-8"?>
          <lexicon version="1.0"
            xmlns="http://www.w3.org/2005/01/pronunciation-lexicon"
            alphabet="ipa" xml:lang="en-US">
            <lexeme><grapheme>AWS</grapheme><alias>Amazon Web Services</alias></lexeme>
          </lexicon>
        PLS
      }
    }
  }

  assert {
    condition     = length(aws_polly_lexicon.this) == 2
    error_message = "Expected 2 lexicons planned, got ${length(aws_polly_lexicon.this)}."
  }
}

# ── Test 3: name_prefix can be empty (no prefix applied) ────────
run "name_prefix_empty_string" {
  command = plan

  variables {
    name_prefix     = ""
    create_iam_role = true
  }

  assert {
    condition     = length(aws_iam_role.polly) == 1
    error_message = "Module should succeed with name_prefix = empty string."
  }
}

# ── Test 4: name_prefix applied to IAM role name ────────────────
run "name_prefix_used_in_role_name" {
  command = plan

  variables {
    name_prefix     = "myapp"
    create_iam_role = true
  }

  assert {
    condition     = aws_iam_role.polly[0].name == "myapp-polly-role"
    error_message = "Expected role name 'myapp-polly-role', got '${aws_iam_role.polly[0].name}'."
  }
}

# ── Test 5: tags are merged with module defaults ─────────────────
run "tags_merged_with_module_defaults" {
  command = plan

  variables {
    create_iam_role = true
    tags = {
      Environment = "test"
      Team        = "platform"
    }
  }

  assert {
    condition     = aws_iam_role.polly[0].tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy=terraform tag on IAM role."
  }

  assert {
    condition     = aws_iam_role.polly[0].tags["Module"] == "tf-aws-polly"
    error_message = "Expected Module=tf-aws-polly tag on IAM role."
  }

  assert {
    condition     = aws_iam_role.polly[0].tags["Environment"] == "test"
    error_message = "Expected caller Environment=test tag to be present on IAM role."
  }
}

# ── Test 6: S3 output disabled by default ───────────────────────
# When enable_s3_output = false, the inline policy should still be
# planned (it just omits the S3 statement).
run "s3_output_disabled_by_default" {
  command = plan

  variables {
    create_iam_role  = true
    enable_s3_output = false
  }

  assert {
    condition     = length(aws_iam_role_policy.polly_inline) == 1
    error_message = "Expected inline policy to be planned even when enable_s3_output = false."
  }
}

# ── Test 7: lexicons output is empty map when none created ───────
run "lexicon_outputs_empty_when_disabled" {
  command = plan

  variables {
    create_lexicons = false
  }

  assert {
    condition     = output.lexicon_names == {}
    error_message = "lexicon_names output should be an empty map when create_lexicons = false."
  }

  assert {
    condition     = output.lexicon_arns == {}
    error_message = "lexicon_arns output should be an empty map when create_lexicons = false."
  }
}
