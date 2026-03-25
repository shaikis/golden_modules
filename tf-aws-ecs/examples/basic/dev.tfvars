aws_region              = "us-east-1"
name                    = "my-app"
environment             = "dev"
container_image         = "nginx:latest"
container_port          = 80
task_cpu                = 256
task_memory             = 512
service_subnets         = ["subnet-aaa", "subnet-bbb"]
service_security_groups = ["sg-0123456789abcdef0"]
desired_count           = 1
tags = {
  Environment = "dev"
}
