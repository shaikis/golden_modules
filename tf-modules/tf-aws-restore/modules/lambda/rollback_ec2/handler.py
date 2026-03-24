import boto3
ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    ec2.associate_address(
        InstanceId=event["old_instance"],
        AllocationId=event["allocation_id"]
    )
    return {"rollback": "done"}