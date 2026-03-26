# ---------------------------------------------------------------------------
# Document Classifier Outputs
# ---------------------------------------------------------------------------

output "document_classifier_arns" {
  description = "Map of document classifier name → ARN."
  value = {
    for k, v in aws_comprehend_document_classifier.this : k => v.arn
  }
}

output "document_classifier_names" {
  description = "Map of document classifier key → resource name (includes name_prefix)."
  value = {
    for k, v in aws_comprehend_document_classifier.this : k => v.name
  }
}

# ---------------------------------------------------------------------------
# Entity Recognizer Outputs
# ---------------------------------------------------------------------------

output "entity_recognizer_arns" {
  description = "Map of entity recognizer key → ARN."
  value = {
    for k, v in aws_comprehend_entity_recognizer.this : k => v.arn
  }
}

output "entity_recognizer_names" {
  description = "Map of entity recognizer key → resource name (includes name_prefix)."
  value = {
    for k, v in aws_comprehend_entity_recognizer.this : k => v.name
  }
}

# ---------------------------------------------------------------------------
# IAM Outputs
# ---------------------------------------------------------------------------

output "iam_role_arn" {
  description = "ARN of the IAM role used by Comprehend. Returns the auto-created role ARN when create_iam_role = true, or the caller-supplied role_arn when create_iam_role = false."
  value       = local.role_arn
}

output "iam_role_name" {
  description = "Name of the auto-created IAM role. Empty string when create_iam_role = false."
  value       = var.create_iam_role ? aws_iam_role.comprehend[0].name : ""
}
