import boto3
ssm = boto3.client("ssm")

def lambda_handler(event, context):
    ssm.send_command(
        InstanceIds=event["instance_ids"],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": event["commands"]}
    )
    return {"mounted": True}