import boto3
r53 = boto3.client("route53")

def lambda_handler(event, context):
    r53.change_resource_record_sets(
        HostedZoneId=event["zone_id"],
        ChangeBatch={
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": event["dns"],
                    "Type": "CNAME",
                    "TTL": 30,
                    "ResourceRecords": [{"Value": event["new_endpoint"]}]
                }
            }]
        }
    )
    return {"rollback": event}