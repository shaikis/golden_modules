aws_region                  = "us-east-1"
name                        = "my-app"
environment                 = "staging"
vpc_id                      = "vpc-0123456789abcdef0"
subnets                     = ["subnet-aaa", "subnet-bbb"]
enable_deletion_protection  = false
target_groups = {
  web = { port = 80 }
}
listeners = {
  http = {
    port     = 80
    protocol = "HTTP"
    default_action = { type = "forward"; target_group_key = "web" }
  }
}
tags = {
  Environment = "staging"
}
