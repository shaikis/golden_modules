aws_region = "us-east-1"

# Replace with real values
alarm_sns_topic_arn     = "arn:aws:sns:us-east-1:123456789012:dms-alerts"
kms_key_arn             = "arn:aws:kms:us-east-1:123456789012:key/mrk-00000000000000000000000000000000"
dms_s3_service_role_arn = "arn:aws:iam::123456789012:role/dms-s3-access-role-us-east-1"
s3_landing_bucket       = "my-data-lake-landing-us-east-1"

oracle_server_name   = "oracle.internal.example.com"
pg_server_name       = "rds-pg.cluster.us-east-1.rds.amazonaws.com"
mysql_server_name    = "rds-mysql.cluster.us-east-1.rds.amazonaws.com"
aurora_server_name   = "aurora-mysql.cluster.us-east-1.rds.amazonaws.com"
redshift_server_name = "my-cluster.xxxx.us-east-1.redshift.amazonaws.com"
