# ---------------------------------------------------------------------------
# Vocabulary outputs
# ---------------------------------------------------------------------------

output "vocabulary_arns" {
  description = "Map of vocabulary name → ARN for all created custom vocabularies."
  value = {
    for k, v in aws_transcribe_vocabulary.this : k => v.id
  }
}

output "vocabulary_names" {
  description = "List of created custom vocabulary names."
  value       = [for v in aws_transcribe_vocabulary.this : v.vocabulary_name]
}

# ---------------------------------------------------------------------------
# Vocabulary filter outputs
# ---------------------------------------------------------------------------

output "vocabulary_filter_arns" {
  description = "Map of filter name → ARN for all created vocabulary filters."
  value = {
    for k, v in aws_transcribe_vocabulary_filter.this : k => v.id
  }
}

output "vocabulary_filter_names" {
  description = "List of created vocabulary filter names."
  value       = [for v in aws_transcribe_vocabulary_filter.this : v.vocabulary_filter_name]
}

# ---------------------------------------------------------------------------
# Language model outputs
# ---------------------------------------------------------------------------

output "language_model_arns" {
  description = "Map of model name → ARN for all created custom language models."
  value = {
    for k, v in aws_transcribe_language_model.this : k => v.id
  }
}

output "language_model_names" {
  description = "List of created custom language model names."
  value       = [for v in aws_transcribe_language_model.this : v.model_name]
}

# ---------------------------------------------------------------------------
# Medical vocabulary outputs
# ---------------------------------------------------------------------------

output "medical_vocabulary_arns" {
  description = "Map of medical vocabulary name → ARN for all created medical vocabularies."
  value = {
    for k, v in aws_transcribe_medical_vocabulary.this : k => v.id
  }
}

output "medical_vocabulary_names" {
  description = "List of created medical vocabulary names."
  value       = [for v in aws_transcribe_medical_vocabulary.this : v.vocabulary_name]
}

# ---------------------------------------------------------------------------
# IAM outputs
# ---------------------------------------------------------------------------

output "iam_role_arn" {
  description = "ARN of the IAM role used by Transcribe resources. Returns the auto-created role or the BYO role ARN."
  value       = local.role_arn
}

output "iam_role_name" {
  description = "Name of the auto-created IAM role. Empty string when using BYO role."
  value       = var.create_iam_role ? aws_iam_role.transcribe[0].name : ""
}
