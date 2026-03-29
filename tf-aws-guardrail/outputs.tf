output "guardrail_id" {
  description = "The Bedrock Guardrail ID."
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "The Bedrock Guardrail ARN."
  value       = aws_bedrock_guardrail.this.arn
}

output "guardrail_version" {
  description = "Published version number (null when create_version = false)."
  value       = try(aws_bedrock_guardrail_version.this[0].version, null)
}

output "guardrail_name" {
  description = "Name of the guardrail."
  value       = aws_bedrock_guardrail.this.name
}
