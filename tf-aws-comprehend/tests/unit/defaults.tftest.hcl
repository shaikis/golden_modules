# ---------------------------------------------------------------------------
# Unit test: default variable values
# command = plan  →  no AWS resources are created, no credentials required.
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"

  # Use a fake account so data sources resolve without real credentials
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# ---------------------------------------------------------------------------
# Test 1: All feature gates are false by default → no resource planned
# ---------------------------------------------------------------------------
run "defaults_no_resources_planned" {
  command = plan

  # Pass no variables — rely entirely on defaults
  variables {}

  # Feature gates default to false
  assert {
    condition     = var.create_document_classifiers == false
    error_message = "create_document_classifiers should default to false"
  }

  assert {
    condition     = var.create_entity_recognizers == false
    error_message = "create_entity_recognizers should default to false"
  }

  # IAM role creation defaults to true
  assert {
    condition     = var.create_iam_role == true
    error_message = "create_iam_role should default to true"
  }

  # No classifiers or recognizers in the plan
  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 0
    error_message = "No document classifiers should be planned when create_document_classifiers = false"
  }

  assert {
    condition     = length(aws_comprehend_entity_recognizer.this) == 0
    error_message = "No entity recognizers should be planned when create_entity_recognizers = false"
  }

  # IAM role IS planned because create_iam_role = true (default)
  assert {
    condition     = length(aws_iam_role.comprehend) == 1
    error_message = "One IAM role should be planned when create_iam_role = true (default)"
  }
}

# ---------------------------------------------------------------------------
# Test 2: BYO IAM role — create_iam_role = false → no aws_iam_role planned
# ---------------------------------------------------------------------------
run "byo_role_no_iam_role_planned" {
  command = plan

  variables {
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/test-comprehend-role"
  }

  assert {
    condition     = length(aws_iam_role.comprehend) == 0
    error_message = "No IAM role should be planned when create_iam_role = false"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.comprehend_full_access) == 0
    error_message = "No IAM policy attachment should be planned when create_iam_role = false"
  }

  assert {
    condition     = length(aws_iam_role_policy.comprehend_inline) == 0
    error_message = "No inline IAM policy should be planned when create_iam_role = false"
  }
}

# ---------------------------------------------------------------------------
# Test 3: name_prefix produces correctly prefixed names
# ---------------------------------------------------------------------------
run "name_prefix_applied" {
  command = plan

  variables {
    name_prefix = "acme"

    create_document_classifiers = true
    document_classifiers = {
      invoices = {
        language_code = "en"
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://acme-data/train.csv"
      }
    }
  }

  assert {
    condition     = aws_comprehend_document_classifier.this["invoices"].name == "acme-invoices"
    error_message = "Document classifier name should be prefixed with 'acme-'"
  }
}

# ---------------------------------------------------------------------------
# Test 4: empty name_prefix produces no leading hyphen
# ---------------------------------------------------------------------------
run "no_name_prefix" {
  command = plan

  variables {
    name_prefix = ""

    create_entity_recognizers = true
    entity_recognizers = {
      products = {
        language_code = "en"
        entity_types  = [{ type = "PRODUCT" }]
        entity_list   = { s3_uri = "s3://acme-data/entities.csv" }
      }
    }
  }

  assert {
    condition     = aws_comprehend_entity_recognizer.this["products"].name == "products"
    error_message = "Entity recognizer name should not have a leading hyphen when name_prefix is empty"
  }
}

# ---------------------------------------------------------------------------
# Test 5: module-level tags are merged onto resources
# ---------------------------------------------------------------------------
run "module_tags_merged" {
  command = plan

  variables {
    tags = {
      Environment = "test"
      Team        = "ml-platform"
    }

    create_entity_recognizers = true
    entity_recognizers = {
      sample = {
        language_code = "en"
        entity_types  = [{ type = "SAMPLE" }]
        entity_list   = { s3_uri = "s3://bucket/list.csv" }
        tags          = { Classifier = "sample" }
      }
    }
  }

  assert {
    condition     = aws_comprehend_entity_recognizer.this["sample"].tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy=terraform tag should be applied automatically"
  }

  assert {
    condition     = aws_comprehend_entity_recognizer.this["sample"].tags["Module"] == "tf-aws-comprehend"
    error_message = "Module=tf-aws-comprehend tag should be applied automatically"
  }

  assert {
    condition     = aws_comprehend_entity_recognizer.this["sample"].tags["Environment"] == "test"
    error_message = "Caller-supplied tags should be present on resources"
  }

  assert {
    condition     = aws_comprehend_entity_recognizer.this["sample"].tags["Classifier"] == "sample"
    error_message = "Per-resource tags should be merged in"
  }
}

# ---------------------------------------------------------------------------
# Test 6: KMS keys are wired through to classifiers
# ---------------------------------------------------------------------------
run "kms_keys_wired" {
  command = plan

  variables {
    kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/model-key"
    volume_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/volume-key"

    create_document_classifiers = true
    document_classifiers = {
      secure = {
        language_code = "en"
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://secure-bucket/train.csv"
      }
    }
  }

  assert {
    condition     = aws_comprehend_document_classifier.this["secure"].model_kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/model-key"
    error_message = "Module-level kms_key_arn should be applied to classifiers"
  }

  assert {
    condition     = aws_comprehend_document_classifier.this["secure"].volume_kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/volume-key"
    error_message = "Module-level volume_kms_key_arn should be applied to classifiers"
  }
}
