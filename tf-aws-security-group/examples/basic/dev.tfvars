aws_region  = "us-east-1"
name        = "web-app"
environment = "dev"
project     = "demo"
owner       = "platform-team"
cost_center = "CC-100"
vpc_id      = "vpc-0123456789abcdef0"
ingress_rules = {
  http = {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "HTTP from internal"
  }
  https = {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "HTTPS from internal"
  }
}
tags = {
  Environment = "dev"
}
