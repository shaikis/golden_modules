# ===========================================================================
# BEDROCK GUARDRAIL
# ===========================================================================
resource "aws_bedrock_guardrail" "this" {
  name                      = local.name
  description               = var.description
  blocked_input_messaging   = var.blocked_input_message
  blocked_outputs_messaging = var.blocked_output_message
  kms_key_arn               = var.kms_key_arn

  # -------------------------------------------------------------------------
  # Topic policy — deny specific conversation topics
  # -------------------------------------------------------------------------
  dynamic "topic_policy_config" {
    for_each = length(var.denied_topics) > 0 ? [1] : []
    content {
      dynamic "topics_config" {
        for_each = var.denied_topics
        content {
          name       = topics_config.value.name
          definition = topics_config.value.definition
          type       = "DENY"
          examples   = topics_config.value.examples
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # Content policy — strength-based harmful content filtering
  # -------------------------------------------------------------------------
  dynamic "content_policy_config" {
    for_each = length(var.content_filters) > 0 ? [1] : []
    content {
      dynamic "filters_config" {
        for_each = var.content_filters
        content {
          type            = filters_config.value.type
          input_strength  = filters_config.value.input_strength
          output_strength = filters_config.value.output_strength
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # Word policy — profanity + custom words
  # -------------------------------------------------------------------------
  dynamic "word_policy_config" {
    for_each = (length(var.managed_word_lists) > 0 || length(var.custom_words) > 0) ? [1] : []
    content {
      dynamic "managed_word_lists_config" {
        for_each = var.managed_word_lists
        content {
          type = managed_word_lists_config.value
        }
      }
      dynamic "words_config" {
        for_each = var.custom_words
        content {
          text = words_config.value
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # Sensitive information policy — PII + custom regex
  # -------------------------------------------------------------------------
  dynamic "sensitive_information_policy_config" {
    for_each = (length(var.pii_entities) > 0 || length(var.regex_patterns) > 0) ? [1] : []
    content {
      dynamic "pii_entities_config" {
        for_each = var.pii_entities
        content {
          type   = pii_entities_config.value.type
          action = pii_entities_config.value.action
        }
      }
      dynamic "regexes_config" {
        for_each = var.regex_patterns
        content {
          name        = regexes_config.value.name
          pattern     = regexes_config.value.pattern
          description = regexes_config.value.description
          action      = regexes_config.value.action
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # Grounding check — RAG hallucination detection
  # -------------------------------------------------------------------------
  dynamic "contextual_grounding_policy_config" {
    for_each = var.grounding_filter != null ? [var.grounding_filter] : []
    content {
      dynamic "filters_config" {
        for_each = [
          { type = "GROUNDING", threshold = contextual_grounding_policy_config.value.grounding_threshold },
          { type = "RELEVANCE", threshold = contextual_grounding_policy_config.value.relevance_threshold }
        ]
        content {
          type      = filters_config.value.type
          threshold = filters_config.value.threshold
        }
      }
    }
  }

  tags = local.tags
}

# ===========================================================================
# GUARDRAIL VERSION (immutable snapshot)
# ===========================================================================
resource "aws_bedrock_guardrail_version" "this" {
  count         = var.create_version ? 1 : 0
  guardrail_arn = aws_bedrock_guardrail.this.arn
  description   = "Terraform-managed version of ${local.name}"
}
