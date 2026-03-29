output "storage_lens_configuration_arn" {
  description = "ARN of the Storage Lens configuration."
  value       = aws_s3control_storage_lens_configuration.this.arn
}

output "storage_lens_configuration_id" {
  description = "Configuration ID of the Storage Lens configuration."
  value       = aws_s3control_storage_lens_configuration.this.config_id
}
