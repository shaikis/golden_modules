aws_region              = "us-east-1"
name                    = "my-app"
environment             = "prod"
container_image         = "nginx:latest"
container_port          = 80
task_cpu                = 1024
task_memory             = 2048
service_subnets         = ["subnet-aaa", "subnet-bbb"]
service_security_groups = ["sg-0123456789abcdef0"]
desired_count           = 3
tags = {
  Environment = "prod"
}
