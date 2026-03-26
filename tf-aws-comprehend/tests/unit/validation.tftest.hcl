# ---------------------------------------------------------------------------
# Unit test: input validation rules
# command = plan  →  each run EXPECTS a plan-time error (expect_failures).
# No AWS resources are created; no credentials required.
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
# Test 1: document_classifiers.mode must be MULTI_CLASS or MULTI_LABEL
# ---------------------------------------------------------------------------
run "reject_invalid_classifier_mode" {
  command = plan

  variables {
    create_document_classifiers = true
    document_classifiers = {
      bad-mode = {
        language_code = "en"
        mode          = "SINGLE_CLASS"  # invalid — should fail validation
        s3_uri        = "s3://bucket/train.csv"
      }
    }
  }

  expect_failures = [var.document_classifiers]
}

# ---------------------------------------------------------------------------
# Test 2: document_classifiers.language_code must be a valid BCP-47 code
# ---------------------------------------------------------------------------
run "reject_invalid_classifier_language_code" {
  command = plan

  variables {
    create_document_classifiers = true
    document_classifiers = {
      bad-lang = {
        language_code = "xx-INVALID"  # invalid — should fail validation
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://bucket/train.csv"
      }
    }
  }

  expect_failures = [var.document_classifiers]
}

# ---------------------------------------------------------------------------
# Test 3: entity_recognizers.entity_types must not be empty
# ---------------------------------------------------------------------------
run "reject_empty_entity_types" {
  command = plan

  variables {
    create_entity_recognizers = true
    entity_recognizers = {
      empty-types = {
        language_code = "en"
        entity_types  = []  # invalid — at least one type required
        entity_list   = { s3_uri = "s3://bucket/list.csv" }
      }
    }
  }

  expect_failures = [var.entity_recognizers]
}

# ---------------------------------------------------------------------------
# Test 4: entity_recognizers.language_code must be a valid BCP-47 code
# ---------------------------------------------------------------------------
run "reject_invalid_recognizer_language_code" {
  command = plan

  variables {
    create_entity_recognizers = true
    entity_recognizers = {
      bad-lang = {
        language_code = "zz"  # invalid — should fail validation
        entity_types  = [{ type = "PRODUCT" }]
        entity_list   = { s3_uri = "s3://bucket/list.csv" }
      }
    }
  }

  expect_failures = [var.entity_recognizers]
}

# ---------------------------------------------------------------------------
# Test 5: entity_recognizers must have at least one training data source
# ---------------------------------------------------------------------------
run "reject_entity_recognizer_no_training_data" {
  command = plan

  variables {
    create_entity_recognizers = true
    entity_recognizers = {
      no-data = {
        language_code = "en"
        entity_types  = [{ type = "PRODUCT" }]
        # entity_list, annotations, and documents all null — invalid
      }
    }
  }

  expect_failures = [var.entity_recognizers]
}

# ---------------------------------------------------------------------------
# Test 6: Valid classifier — MULTI_CLASS with English should pass
# ---------------------------------------------------------------------------
run "accept_valid_classifier_multi_class" {
  command = plan

  variables {
    create_document_classifiers = true
    document_classifiers = {
      valid = {
        language_code = "en"
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://bucket/train.csv"
      }
    }
  }

  # No expect_failures — this run must succeed
  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 1
    error_message = "One document classifier should be planned for a valid config"
  }
}

# ---------------------------------------------------------------------------
# Test 7: Valid classifier — MULTI_LABEL with label_delimiter should pass
# ---------------------------------------------------------------------------
run "accept_valid_classifier_multi_label" {
  command = plan

  variables {
    create_document_classifiers = true
    document_classifiers = {
      topics = {
        language_code   = "en"
        mode            = "MULTI_LABEL"
        label_delimiter = "|"
        s3_uri          = "s3://bucket/train.csv"
      }
    }
  }

  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 1
    error_message = "One MULTI_LABEL document classifier should be planned for a valid config"
  }
}

# ---------------------------------------------------------------------------
# Test 8: Valid entity recognizer with all three training sources
# ---------------------------------------------------------------------------
run "accept_entity_recognizer_all_sources" {
  command = plan

  variables {
    create_entity_recognizers = true
    entity_recognizers = {
      full = {
        language_code = "es"
        entity_types = [
          { type = "PERSON" },
          { type = "LOCATION" },
        ]
        entity_list  = { s3_uri = "s3://bucket/entity-list.csv" }
        annotations  = { s3_uri = "s3://bucket/annotations.csv" }
        documents = {
          s3_uri       = "s3://bucket/docs.txt"
          input_format = "ONE_DOC_PER_LINE"
        }
      }
    }
  }

  assert {
    condition     = length(aws_comprehend_entity_recognizer.this) == 1
    error_message = "One entity recognizer should be planned for a valid config"
  }
}

# ---------------------------------------------------------------------------
# Test 9: Multiple classifiers — for_each creates the correct count
# ---------------------------------------------------------------------------
run "multiple_classifiers_for_each" {
  command = plan

  variables {
    create_document_classifiers = true
    document_classifiers = {
      finance = {
        language_code = "en"
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://bucket/finance-train.csv"
      }
      legal = {
        language_code = "fr"
        mode          = "MULTI_LABEL"
        label_delimiter = "|"
        s3_uri        = "s3://bucket/legal-train.csv"
      }
    }
  }

  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 2
    error_message = "Two document classifiers should be planned when two entries are supplied"
  }
}
