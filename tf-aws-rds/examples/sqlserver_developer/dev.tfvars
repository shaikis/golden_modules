aws_region = "us-west-2"

name        = "sqlserver-dev"
environment = "dev"
project     = "golden-modules"
owner       = "platform"
cost_center = "engineering"

instance_class = "db.m6i.large"
timezone       = "UTC"
username       = "dbadmin"

allocated_storage     = 200
max_allocated_storage = 500
storage_type          = "gp3"

kms_key_arn          = "arn:aws:kms:us-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
db_subnet_group_name = "example-private-db-subnets"
vpc_security_group_ids = [
  "sg-0123456789abcdef0"
]

sqlserver_developer_custom_engine_version_name = "16.00.4215.2.my-dev-cev"
sqlserver_developer_media_bucket_name          = "my-sqlserver-dev-installation-media"
sqlserver_developer_media_bucket_prefix        = "sqlserver-dev-media"
sqlserver_developer_media_files = [
  "SQLServer2022-x64-ENU-Dev.iso",
  "SQLServer2022-KB5065865-x64.exe"
]
