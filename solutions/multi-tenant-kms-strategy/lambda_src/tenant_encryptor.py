import base64
import json
import os

import boto3


def assume_role_for_tenant(tenant_id: str):
    alias = f"alias/customer-{tenant_id}"
    role_arn = os.environ["SERVICE_A_ROLE_ARN"]

    session_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:GenerateDataKey*",
                    "kms:DescribeKey",
                ],
                "Resource": "*",
                "Condition": {
                    "StringEquals": {
                        "kms:RequestAlias": alias
                    }
                },
            }
        ],
    }

    sts = boto3.client("sts")
    return sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName=f"tenant-{tenant_id}-kms",
        Policy=json.dumps(session_policy),
    )["Credentials"]


def handler(event, context):
    tenant_id = event["tenant_id"]
    plaintext = event["plaintext"]
    table_name = os.environ["DDB_TABLE_NAME"]
    kms_region = os.environ["CENTRAL_KMS_REGION"]

    creds = assume_role_for_tenant(tenant_id)

    kms = boto3.client(
        "kms",
        region_name=kms_region,
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )

    response = kms.encrypt(
        KeyId=f"alias/customer-{tenant_id}",
        Plaintext=plaintext.encode("utf-8"),
    )

    ciphertext_b64 = base64.b64encode(response["CiphertextBlob"]).decode("utf-8")

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    table.put_item(
        Item={
            "pk": f"TENANT#{tenant_id}",
            "sk": f"SECRET#{context.aws_request_id}",
            "tenant_id": tenant_id,
            "ciphertext_b64": ciphertext_b64,
            "kms_alias": f"alias/customer-{tenant_id}",
        }
    )

    return {
        "statusCode": 200,
        "tenant_id": tenant_id,
        "kms_alias": f"alias/customer-{tenant_id}",
    }
