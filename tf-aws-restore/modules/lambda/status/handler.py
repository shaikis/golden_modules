import boto3

rds = boto3.client("rds")

def lambda_handler(event, context):
    db = rds.describe_db_instances()["DBInstances"][0]
    return {"status": db["DBInstanceStatus"], **event}