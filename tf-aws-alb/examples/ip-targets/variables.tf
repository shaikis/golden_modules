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

variable "api_container_image" {
  description = "Docker image URI for the ECS Fargate API task."
  type        = string
  default     = "nginx:latest"
}

variable "fargate_desired_count" {
  description = "Desired number of Fargate tasks."
  type        = number
  default     = 2
}

variable "onprem_server_ips" {
  description = "Private IPs of on-premises servers reachable over VPN/Direct Connect."
  type        = list(string)
  default     = []
  # example: ["192.168.10.5", "192.168.10.6"]
}

variable "peered_service_ips" {
  description = "Private IPs of services in a peered VPC."
  type        = list(string)
  default     = []
  # example: ["10.1.2.10", "10.1.2.11"]
}
