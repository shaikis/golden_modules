variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "config_id" {
  type    = string
  default = "example-storage-lens"
}

variable "reports_bucket_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Terraform   = "true"
  }
}
