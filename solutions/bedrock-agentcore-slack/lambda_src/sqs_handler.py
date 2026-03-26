"""
SQS Integration Lambda
======================
1. Filters bot messages to prevent infinite response loops.
2. Posts a placeholder Processing message to the Slack thread.
3. Enqueues the message to SQS FIFO for agent processing.
   Session ID = thread_ts ensures per-thread conversation isolation.
"""
import json
import logging
import os
import urllib.request

import boto3

logger         = logging.getLogger()
logger.setLevel(logging.INFO)
secretsmanager = boto3.client("secretsmanager")
sqs            = boto3.client("sqs")

_CACHE = {}


def _get_bot_token() -> str:
    if "token" not in _CACHE:
        resp = secretsmanager.get_secret_value(SecretId=os.environ["SLACK_SECRET_ARN"])
        _CACHE["token"] = json.loads(resp["SecretString"])["bot_token"]
    return _CACHE["token"]


def _slack_post(method: str, payload: dict) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req  = urllib.request.Request(
        f"https://slack.com/api/{method}",
        data=data,
        headers={"Authorization": f"Bearer {_get_bot_token()}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def lambda_handler(event, context):
    slack_event = event.get("event", {})

    if slack_event.get("bot_id") or slack_event.get("subtype") in ("bot_message", "message_changed"):
        logger.info("Ignoring bot message")
        return {"statusCode": 200}

    user_id   = slack_event.get("user", "")
    channel   = slack_event.get("channel", "")
    text      = slack_event.get("text", "").strip()
    ts        = slack_event.get("ts", "")
    thread_ts = slack_event.get("thread_ts") or ts

    if not text or not channel:
        return {"statusCode": 200}

    placeholder_resp = _slack_post("chat.postMessage", {
        "channel":   channel,
        "thread_ts": thread_ts,
        "text":      ":hourglass_flowing_sand: Processing your request...",
    })
    placeholder_ts = placeholder_resp.get("ts", "")
    logger.info("Placeholder posted ts=%s", placeholder_ts)

    sqs.send_message(
        QueueUrl              = os.environ["SQS_QUEUE_URL"],
        MessageBody           = json.dumps({
            "user_id":        user_id,
            "channel":        channel,
            "text":           text,
            "thread_ts":      thread_ts,
            "placeholder_ts": placeholder_ts,
        }),
        MessageGroupId        = f"{channel}-{thread_ts}",
        MessageDeduplicationId= ts,
    )
    logger.info("Message enqueued — user=%s thread=%s", user_id, thread_ts)
    return {"statusCode": 200}
