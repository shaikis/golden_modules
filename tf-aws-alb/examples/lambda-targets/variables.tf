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

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}
