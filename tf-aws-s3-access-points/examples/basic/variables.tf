variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type = string
}

variable "project" {
  type    = string
  default = "example"
}

variable "vpc_id" {
  type    = string
  default = "vpc-12345678"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Terraform   = "true"
  }
}
