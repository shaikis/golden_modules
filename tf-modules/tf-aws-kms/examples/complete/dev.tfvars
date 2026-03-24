aws_region  = "us-east-1"
name        = "data-encryption"
name_prefix = "myapp"
environment = "dev"
project     = "fintech-platform"
owner       = "security-team"
cost_center = "CC-1234"
tags        = {}

description              = "Encrypts application data and secrets in dev"
key_usage                = "ENCRYPT_DECRYPT"
customer_master_key_spec = "SYMMETRIC_DEFAULT"
enable_key_rotation      = true
deletion_window_in_days  = 7
multi_region             = false

kms_admin_role_name   = "KMSAdminRole"
app_server_role_name  = "AppServerRole"
lambda_exec_role_name = "LambdaExecRole"
autoscaling_role_path = "aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

aliases = ["dev/app-data", "dev/secrets"]
