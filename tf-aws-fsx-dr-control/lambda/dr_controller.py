import base64
import json
import os
import ssl
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

import boto3


secretsmanager = boto3.client("secretsmanager")
route53 = boto3.client("route53")
dynamodb = boto3.client("dynamodb")
sns = boto3.client("sns")


def _load_secret(secret_arn: str) -> dict:
    response = secretsmanager.get_secret_value(SecretId=secret_arn)
    secret_string = response.get("SecretString")
    if secret_string:
        return json.loads(secret_string)
    return json.loads(base64.b64decode(response["SecretBinary"]).decode("utf-8"))


def _ontap_rest(event: dict) -> dict:
    secret = _load_secret(event["secret_arn"])
    hostname = secret["hostname"]
    username = secret["username"]
    password = secret["password"]
    port = int(secret.get("port", 443))
    method = event.get("method", "GET").upper()
    path = event["path"]
    query = event.get("query") or {}
    body = event.get("body")
    expected_statuses = event.get("expected_statuses") or [200, 202]
    validate_certs = event.get("validate_certs", False)

    query_string = urllib.parse.urlencode(query)
    url = f"https://{hostname}:{port}{path}"
    if query_string:
      url = f"{url}?{query_string}"

    data = None
    headers = {"Accept": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    token = base64.b64encode(f"{username}:{password}".encode("utf-8")).decode("utf-8")
    headers["Authorization"] = f"Basic {token}"

    request = urllib.request.Request(url=url, method=method, headers=headers, data=data)
    context = None
    if not validate_certs:
        context = ssl._create_unverified_context()

    try:
        with urllib.request.urlopen(request, context=context, timeout=60) as response:
            payload = response.read().decode("utf-8") if response.length != 0 else ""
            body_json = json.loads(payload) if payload else {}
            if response.status not in expected_statuses:
                raise RuntimeError(f"Unexpected ONTAP status {response.status}: {body_json}")
            return {
                "status_code": response.status,
                "response": body_json,
                "url": url,
            }
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8")
        raise RuntimeError(f"ONTAP API call failed with status {exc.code}: {payload}") from exc


def _update_dns(event: dict) -> dict:
    zone_id = event.get("zone_id") or os.environ["DEFAULT_ROUTE53_ZONE_ID"]
    record_name = event.get("record_name") or os.environ["DEFAULT_ROUTE53_NAME"]
    record_type = event.get("record_type") or os.environ["DEFAULT_ROUTE53_TYPE"] or "CNAME"
    ttl = int(event.get("ttl") or os.environ.get("DEFAULT_ROUTE53_TTL", "30"))
    records = event.get("records") or []
    if not zone_id or not record_name or not records:
        raise ValueError("dns_change requires zone_id, record_name, and records.")

    response = route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch={
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": record_name,
                    "Type": record_type,
                    "TTL": ttl,
                    "ResourceRecords": [{"Value": value} for value in records],
                },
            }]
        },
    )

    return {
        "status": "submitted",
        "change_id": response["ChangeInfo"]["Id"],
        "record_name": record_name,
        "records": records,
    }


def _record_state(event: dict) -> dict:
    table_name = os.environ.get("STATE_TABLE_NAME", "")
    if not table_name:
        return {"status": "skipped", "reason": "STATE_TABLE_NAME not configured"}

    workflow_key = event["workflow_key"]
    attributes = event.get("attributes") or {}
    item = {
        "workflow_key": {"S": workflow_key},
        "updated_at": {"S": datetime.now(timezone.utc).isoformat()},
        "payload": {"S": json.dumps(attributes)},
    }

    dynamodb.put_item(TableName=table_name, Item=item)
    return {"status": "stored", "workflow_key": workflow_key}


def _notify(event: dict) -> dict:
    topic_arn = event.get("topic_arn") or os.environ.get("DEFAULT_SNS_TOPIC_ARN", "")
    if not topic_arn:
        return {"status": "skipped", "reason": "No SNS topic configured"}

    sns.publish(
        TopicArn=topic_arn,
        Subject=event.get("subject", "FSx ONTAP DR workflow"),
        Message=event.get("message", json.dumps(event)),
    )
    return {"status": "sent", "topic_arn": topic_arn}


def _precheck(event: dict) -> dict:
    execution_input = event.get("execution_input") or {}
    ontap_actions = execution_input.get("ontap_actions") or []

    for action in ontap_actions:
        if action.get("action") != "ontap_rest":
            raise ValueError("All ontap_actions must use action = ontap_rest.")
        if "secret_arn" not in action or "path" not in action:
            raise ValueError("Each ontap_action requires secret_arn and path.")

    return {
        "status": "ok",
        "execution_input": execution_input,
    }


def handler(event, context):
    action = event.get("action")
    if action == "precheck":
        return _precheck(event)
    if action == "ontap_rest":
        return _ontap_rest(event)
    if action == "update_dns":
        return _update_dns(event)
    if action == "record_state":
        return _record_state(event)
    if action == "notify":
        return _notify(event)
    raise ValueError(f"Unsupported action: {action}")
