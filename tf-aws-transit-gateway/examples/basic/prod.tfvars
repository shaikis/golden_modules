aws_region  = "us-east-1"
name        = "platform-hub"
environment = "prod"
project     = "networking"
owner       = "network-team"
cost_center = "CC-100"
vpc_attachments = {
  shared_services = {
    vpc_id     = "vpc-shared"
    subnet_ids = ["subnet-ss-a", "subnet-ss-b"]
  }
  app_prod = {
    vpc_id     = "vpc-app"
    subnet_ids = ["subnet-app-a", "subnet-app-b"]
  }
  data_prod = {
    vpc_id     = "vpc-data"
    subnet_ids = ["subnet-data-a", "subnet-data-b"]
  }
}
tags = {
  Environment = "prod"
}
