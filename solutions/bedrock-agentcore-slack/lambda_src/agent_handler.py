"""
Agent Integration Lambda
========================
Triggered by SQS FIFO queue.
1. Invokes Bedrock Agent using thread_ts as session ID (conversation memory).
2. Assembles the streaming agent response.
3. Updates the Slack placeholder message with the final answer.
4. On failure: updates placeholder with error and re-raises for DLQ routing.
"""
import json
import logging
import os
import urllib.request

import boto3

logger                = logging.getLogger()
logger.setLevel(logging.INFO)
bedrock_agent_runtime = boto3.client("bedrock-agent-runtime")
secretsmanager        = boto3.client("secretsmanager")

_CACHE = {}


def _get_bot_token() -> str:
    if "token" not in _CACHE:
        resp = secretsmanager.get_secret_value(SecretId=os.environ["SLACK_SECRET_ARN"])
        _CACHE["token"] = json.loads(resp["SecretString"])["bot_token"]
    return _CACHE["token"]


def _slack_update(channel: str, ts: str, text: str) -> None:
    data = json.dumps({"channel": channel, "ts": ts, "text": text}).encode("utf-8")
    req  = urllib.request.Request(
        "https://slack.com/api/chat.update",
        data=data,
        headers={"Authorization": f"Bearer {_get_bot_token()}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        result = json.loads(resp.read())
        if not result.get("ok"):
            logger.warning("chat.update failed: %s", result)


def _invoke_agent(user_id: str, thread_ts: str, text: str) -> str:
    session_id = f"{thread_ts.replace('.', '-')}-{user_id}"[:100]

    invoke_kwargs = {
        "agentId":      os.environ["BEDROCK_AGENT_ID"],
        "agentAliasId": os.environ["BEDROCK_AGENT_ALIAS_ID"],
        "sessionId":    session_id,
        "inputText":    text,
    }

    guardrail_id = os.environ.get("BEDROCK_GUARDRAIL_ID", "")
    if guardrail_id:
        invoke_kwargs["guardrailConfiguration"] = {
            "guardrailId":      guardrail_id,
            "guardrailVersion": os.environ.get("BEDROCK_GUARDRAIL_VERSION", "DRAFT"),
        }

    response = bedrock_agent_runtime.invoke_agent(**invoke_kwargs)
    chunks   = []
    for stream_event in response.get("completion", []):
        chunk = stream_event.get("chunk", {})
        if "bytes" in chunk:
            chunks.append(chunk["bytes"].decode("utf-8"))

    return "".join(chunks).strip() or "I could not generate a response."


def lambda_handler(event, context):
    for record in event.get("Records", []):
        payload        = json.loads(record["body"])
        user_id        = payload["user_id"]
        channel        = payload["channel"]
        text           = payload["text"]
        thread_ts      = payload["thread_ts"]
        placeholder_ts = payload.get("placeholder_ts", "")

        logger.info("Invoking agent for user=%s thread=%s", user_id, thread_ts)

        try:
            response_text = _invoke_agent(user_id, thread_ts, text)
        except Exception as exc:
            logger.exception("Agent invocation failed: %s", exc)
            if placeholder_ts:
                _slack_update(channel, placeholder_ts, ":x: Sorry, I encountered an error. Please try again.")
            raise

        if placeholder_ts:
            _slack_update(channel, placeholder_ts, response_text)

    return {"statusCode": 200}
