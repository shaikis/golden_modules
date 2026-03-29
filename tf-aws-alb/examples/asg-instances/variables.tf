variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "myapp"
}
variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional)."
  type        = string
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "asg_min_size" {
  type    = number
  default = 2
}
variable "asg_max_size" {
  type    = number
  default = 10
}
variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs. Empty = disabled."
  type        = string
  default     = ""
}

variable "admin_allowed_cidrs" {
  description = "CIDR blocks allowed to reach /admin/*."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
