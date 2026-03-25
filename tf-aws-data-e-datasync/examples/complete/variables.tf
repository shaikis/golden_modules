variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms."
  type        = string
  default     = null
}

variable "raw_bucket_arn" {
  description = "S3 ARN for the raw data zone bucket."
  type        = string
}

variable "archive_bucket_arn" {
  description = "S3 ARN for the archive/cold storage bucket."
  type        = string
}

variable "efs_file_system_arn" {
  description = "EFS file system ARN for EFS-to-S3 backup task."
  type        = string
}

variable "efs_subnet_arn" {
  description = "Subnet ARN for EFS DataSync access."
  type        = string
}

variable "efs_security_group_arns" {
  description = "Security group ARNs for EFS DataSync access."
  type        = list(string)
}

variable "nfs_agent_arns" {
  description = "DataSync agent ARNs for NFS on-premises access."
  type        = list(string)
}

variable "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for DataSync task logging."
  type        = string
  default     = null
}

variable "report_bucket_arn" {
  description = "S3 bucket ARN for DataSync task reports."
  type        = string
  default     = null
}
