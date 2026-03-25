import boto3, datetime

backup = boto3.client("backup")

def lambda_handler(event, context):
    points = backup.list_recovery_points_by_resource(
        ResourceArn=event["resource_identifier"]
    )["RecoveryPoints"]

    latest = sorted(points, key=lambda x: x["CreationDate"], reverse=True)[0]

    meta = backup.get_recovery_point_restore_metadata(
        RecoveryPointArn=latest["RecoveryPointArn"]
    )["RestoreMetadata"]

    suffix = datetime.datetime.utcnow().strftime("%Y%m%d%H%M")

    if "DBInstanceIdentifier" in meta:
        meta["DBInstanceIdentifier"] += f"-bg-{suffix}"

    res = backup.start_restore_job(
        RecoveryPointArn=latest["RecoveryPointArn"],
        Metadata=meta,
        IamRoleArn=event["iam_role"]
    )

    return {"job_id": res["RestoreJobId"], **event}