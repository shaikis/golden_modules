"""
Slack Verification Lambda
=========================
1. Validates Slack HMAC-SHA256 webhook signature.
2. Returns HTTP 200 immediately to satisfy Slack 3-second timeout.
3. Handles Slack URL verification challenge (app setup).
4. Asynchronously invokes SQS Integration Lambda (fire-and-forget).
"""
import hashlib
import hmac
import json
import logging
import os
import time

import boto3

logger         = logging.getLogger()
logger.setLevel(logging.INFO)
secretsmanager = boto3.client("secretsmanager")
lambda_client  = boto3.client("lambda")

_CACHE = {}


def _get_slack_credentials():
    if "creds" not in _CACHE:
        resp = secretsmanager.get_secret_value(SecretId=os.environ["SLACK_SECRET_ARN"])
        _CACHE["creds"] = json.loads(resp["SecretString"])
    return _CACHE["creds"]


def _verify_signature(headers: dict, raw_body: str) -> bool:
    creds     = _get_slack_credentials()
    secret    = creds["signing_secret"]
    timestamp = headers.get("x-slack-request-timestamp", "")
    signature = headers.get("x-slack-signature", "")

    if not timestamp or not signature:
        return False
    if abs(time.time() - int(timestamp)) > 300:
        logger.warning("Slack request timestamp too old")
        return False

    sig_basestring = f"v0:{timestamp}:{raw_body}"
    expected = "v0=" + hmac.new(
        secret.encode("utf-8"),
        sig_basestring.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(expected, signature)


def lambda_handler(event, context):
    if event.get("requestContext", {}).get("http", {}).get("method") == "GET":
        return {"statusCode": 200, "body": json.dumps({"status": "ok"})}

    raw_body = event.get("body", "") or ""
    headers  = {k.lower(): v for k, v in (event.get("headers") or {}).items()}

    if not _verify_signature(headers, raw_body):
        logger.warning("Invalid Slack signature")
        return {"statusCode": 401, "body": "Unauthorized"}

    try:
        payload = json.loads(raw_body)
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": "Bad Request"}

    if payload.get("type") == "url_verification":
        logger.info("Responding to Slack URL verification challenge")
        return {
            "statusCode": 200,
            "headers":    {"Content-Type": "application/json"},
            "body":       json.dumps({"challenge": payload["challenge"]}),
        }

    lambda_client.invoke(
        FunctionName  = os.environ["SQS_INTEGRATION_FUNCTION_NAME"],
        InvocationType= "Event",
        Payload       = json.dumps(payload).encode(),
    )
    logger.info("Async invocation of SQS integration triggered")
    return {"statusCode": 200, "body": ""}
