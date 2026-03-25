aws_region                  = "us-east-1"
name                        = "my-app"
environment                 = "prod"
vpc_id                      = "vpc-0123456789abcdef0"
subnets                     = ["subnet-aaa", "subnet-bbb"]
enable_deletion_protection  = true
target_groups = {
  web = { port = 80 }
}
listeners = {
  http = {
    port     = 80
    protocol = "HTTP"
    default_action = { type = "redirect"; redirect = { port = "443"; protocol = "HTTPS"; status_code = "HTTP_301" } }
  }
  https = {
    port            = 443
    protocol        = "HTTPS"
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/placeholder"
    default_action  = { type = "forward"; target_group_key = "web" }
  }
}
tags = {
  Environment = "prod"
}
