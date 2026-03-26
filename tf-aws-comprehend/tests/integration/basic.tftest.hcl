# ---------------------------------------------------------------------------
# Integration test: basic end-to-end plan
#
# SKIP_IN_CI (apply):
#   AWS Comprehend custom model training costs ~$3+/hour and takes 30–90
#   minutes. This test uses `command = plan` only to validate that Terraform
#   produces a correct, error-free configuration for a realistic scenario.
#   Never run `terraform apply` in CI without explicitly accounting for the
#   training cost and wait time in your pipeline budget.
#
# command = plan  →  validates the plan; zero AWS resources are created.
# ---------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------------------------
# Scenario A: Entity recognizer for product NER
# ---------------------------------------------------------------------------
run "plan_entity_recognizer_product_ner" {
  command = plan

  variables {
    name_prefix = "integ-test"

    create_entity_recognizers = true

    entity_recognizers = {
      product-ner = {
        language_code = "en"

        entity_types = [
          { type = "PRODUCT" },
          { type = "SKU" },
          { type = "BRAND" },
        ]

        entity_list = {
          s3_uri = "s3://acme-ml-integ/comprehend/product-entity-list.csv"
        }

        version_name = "v1"

        tags = {
          Test = "integration"
          Tier = "product-ner"
        }
      }
    }

    tags = {
      Environment = "integration-test"
      ManagedBy   = "terraform-test"
    }
  }

  # Plan produces exactly one entity recognizer
  assert {
    condition     = length(aws_comprehend_entity_recognizer.this) == 1
    error_message = "Exactly one entity recognizer should appear in the plan"
  }

  # Name includes the prefix
  assert {
    condition     = aws_comprehend_entity_recognizer.this["product-ner"].name == "integ-test-product-ner"
    error_message = "Recognizer name should be 'integ-test-product-ner'"
  }

  # Language code flows through
  assert {
    condition     = aws_comprehend_entity_recognizer.this["product-ner"].language_code == "en"
    error_message = "language_code should be 'en'"
  }

  # IAM role is auto-created (create_iam_role defaults to true)
  assert {
    condition     = length(aws_iam_role.comprehend) == 1
    error_message = "One IAM role should appear in the plan"
  }

  # No document classifiers in this scenario
  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 0
    error_message = "No document classifiers should appear in this plan"
  }
}

# ---------------------------------------------------------------------------
# Scenario B: Document classifier with BYO IAM role and KMS encryption
# ---------------------------------------------------------------------------
run "plan_document_classifier_byo_iam_kms" {
  command = plan

  variables {
    name_prefix = "integ-byo"

    # BYO IAM role from a separate tf-aws-iam module deployment
    create_iam_role = false
    role_arn        = "arn:aws:iam::123456789012:role/existing-comprehend-role"

    # KMS keys from a separate tf-aws-kms module deployment
    kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/aaaa-bbbb-cccc-dddd"
    volume_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/eeee-ffff-0000-1111"

    create_document_classifiers = true

    document_classifiers = {
      support-tickets = {
        language_code = "en"
        mode          = "MULTI_CLASS"
        s3_uri        = "s3://acme-ml-integ/support/train.csv"
        test_s3_uri   = "s3://acme-ml-integ/support/test.csv"
        version_name  = "v1"

        tags = { UseCase = "support-routing" }
      }
    }

    tags = {
      Environment = "integration-test"
    }
  }

  # No IAM role resource — using BYO
  assert {
    condition     = length(aws_iam_role.comprehend) == 0
    error_message = "No IAM role should appear in the plan when create_iam_role = false"
  }

  # One classifier
  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 1
    error_message = "One document classifier should appear in the plan"
  }

  # Name includes the BYO prefix
  assert {
    condition     = aws_comprehend_document_classifier.this["support-tickets"].name == "integ-byo-support-tickets"
    error_message = "Classifier name should include 'integ-byo-' prefix"
  }

  # Mode is MULTI_CLASS
  assert {
    condition     = aws_comprehend_document_classifier.this["support-tickets"].mode == "MULTI_CLASS"
    error_message = "Classifier mode should be MULTI_CLASS"
  }

  # KMS key is applied
  assert {
    condition     = aws_comprehend_document_classifier.this["support-tickets"].model_kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/aaaa-bbbb-cccc-dddd"
    error_message = "Module-level KMS key should be applied to the classifier"
  }

  # data_access_role_arn uses the BYO role
  assert {
    condition     = aws_comprehend_document_classifier.this["support-tickets"].data_access_role_arn == "arn:aws:iam::123456789012:role/existing-comprehend-role"
    error_message = "data_access_role_arn should use the BYO role ARN"
  }
}

# ---------------------------------------------------------------------------
# Scenario C: Multi-label classifier + entity recognizer together
# ---------------------------------------------------------------------------
run "plan_classifier_and_recognizer_together" {
  command = plan

  variables {
    name_prefix = "acme-prod"

    create_document_classifiers = true
    create_entity_recognizers   = true

    document_classifiers = {
      content-topics = {
        language_code   = "en"
        mode            = "MULTI_LABEL"
        label_delimiter = "|"
        s3_uri          = "s3://acme-prod/content/train.csv"
      }
    }

    entity_recognizers = {
      product-extractor = {
        language_code = "en"
        entity_types  = [{ type = "PRODUCT" }]
        entity_list   = { s3_uri = "s3://acme-prod/entities/products.csv" }
      }

      org-extractor = {
        language_code = "en"
        entity_types  = [{ type = "ORGANIZATION" }]
        annotations = {
          s3_uri      = "s3://acme-prod/annotations/orgs.csv"
          test_s3_uri = "s3://acme-prod/annotations/orgs-test.csv"
        }
      }
    }

    tags = {
      Environment = "production"
      CostCenter  = "ml-platform"
    }
  }

  # One document classifier
  assert {
    condition     = length(aws_comprehend_document_classifier.this) == 1
    error_message = "Exactly one document classifier should appear in the plan"
  }

  # Two entity recognizers
  assert {
    condition     = length(aws_comprehend_entity_recognizer.this) == 2
    error_message = "Exactly two entity recognizers should appear in the plan"
  }

  # Correct resource names
  assert {
    condition     = contains(keys(aws_comprehend_entity_recognizer.this), "product-extractor")
    error_message = "product-extractor recognizer should be in the plan"
  }

  assert {
    condition     = contains(keys(aws_comprehend_entity_recognizer.this), "org-extractor")
    error_message = "org-extractor recognizer should be in the plan"
  }
}

# ---------------------------------------------------------------------------
# Scenario D: VPC-isolated entity recognizer for PII
# ---------------------------------------------------------------------------
run "plan_vpc_isolated_pii_recognizer" {
  command = plan

  variables {
    name_prefix = "secure"

    create_entity_recognizers = true

    entity_recognizers = {
      pii-detector = {
        language_code = "en"
        entity_types = [
          { type = "EMPLOYEE_ID" },
          { type = "BADGE_NUMBER" },
        ]
        entity_list = { s3_uri = "s3://secure-bucket/pii/entity-list.csv" }

        vpc_config = {
          security_group_ids = ["sg-0abc123def456789a"]
          subnets            = ["subnet-0111aaabbbccc0001", "subnet-0222dddeee0002"]
        }
      }
    }
  }

  assert {
    condition     = length(aws_comprehend_entity_recognizer.this) == 1
    error_message = "One VPC-isolated entity recognizer should appear in the plan"
  }

  assert {
    condition     = length(aws_comprehend_entity_recognizer.this["pii-detector"].vpc_config) == 1
    error_message = "VPC config block should be present on the recognizer"
  }
}
