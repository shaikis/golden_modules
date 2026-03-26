"""
Telemetry Embedding Lambda
==========================
Triggered by Kinesis Data Stream (Fluent Bit -> Kinesis).
For each batch of records:
  1. Base64-decode + JSON-parse each Kinesis record
  2. Normalize: extract log message, source (pod/namespace/node), timestamp, log_level
  3. Call Bedrock Titan Embed to generate 1024-dim vector
  4. Bulk-index into OpenSearch Serverless VECTORSEARCH collection
  5. Failed records -> S3 DLQ bucket

Uses batching for efficiency (KINESIS_BATCH_SIZE env var controls batch size from trigger).
"""
import base64
import json
import logging
import os
import time
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import urllib.request
import urllib.error

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

bedrock   = boto3.client("bedrock-runtime")
s3        = boto3.client("s3")
session   = boto3.Session()

OPENSEARCH_ENDPOINT = os.environ["OPENSEARCH_ENDPOINT"]
INDEX_NAME          = os.environ["INDEX_NAME"]
EMBEDDING_MODEL_ID  = os.environ["EMBEDDING_MODEL_ID"]
VECTOR_DIMENSIONS   = int(os.environ.get("VECTOR_DIMENSIONS", "1024"))
DLQ_BUCKET          = os.environ.get("DLQ_BUCKET", "")
AWS_REGION          = os.environ.get("AWS_REGION", "us-east-1")


def _generate_embedding(text: str) -> list:
    """Call Bedrock Titan Embed to generate a 1024-dim vector."""
    resp = bedrock.invoke_model(
        modelId=EMBEDDING_MODEL_ID,
        body=json.dumps({"inputText": text[:8192]}),  # Titan Embed v2 max input
        contentType="application/json",
        accept="application/json",
    )
    body = json.loads(resp["body"].read())
    return body["embedding"]


def _normalize_record(raw: dict) -> dict:
    """Extract consistent fields from Fluent Bit JSON record."""
    return {
        "timestamp":  raw.get("time", raw.get("@timestamp", datetime.now(timezone.utc).isoformat())),
        "log":        raw.get("log", raw.get("message", str(raw))),
        "namespace":  raw.get("kubernetes", {}).get("namespace_name", raw.get("namespace", "unknown")),
        "pod":        raw.get("kubernetes", {}).get("pod_name", raw.get("pod", "unknown")),
        "container":  raw.get("kubernetes", {}).get("container_name", raw.get("container", "unknown")),
        "node":       raw.get("kubernetes", {}).get("host", raw.get("node", "unknown")),
        "log_level":  raw.get("level", raw.get("severity", "INFO")).upper(),
        "source":     raw.get("stream", "stdout"),
    }


def _os_request(method: str, path: str, body: dict = None) -> dict:
    """Sign and send a request to OpenSearch Serverless."""
    url      = f"{OPENSEARCH_ENDPOINT.rstrip('/')}{path}"
    payload  = json.dumps(body).encode() if body else b""
    creds    = session.get_credentials().get_frozen_credentials()

    request = AWSRequest(method=method, url=url, data=payload,
                         headers={"Content-Type": "application/json"})
    SigV4Auth(creds, "aoss", AWS_REGION).add_auth(request)

    req = urllib.request.Request(
        url, data=payload, method=method,
        headers=dict(request.headers),
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def _bulk_index(documents: list) -> None:
    """Bulk-index documents into OpenSearch."""
    if not documents:
        return

    lines = []
    for doc in documents:
        lines.append(json.dumps({"index": {"_index": INDEX_NAME}}))
        lines.append(json.dumps(doc))

    bulk_body_str = "\n".join(lines) + "\n"

    url     = f"{OPENSEARCH_ENDPOINT.rstrip('/')}/{INDEX_NAME}/_bulk"
    payload = bulk_body_str.encode()
    creds   = session.get_credentials().get_frozen_credentials()

    request = AWSRequest(method="POST", url=url, data=payload,
                         headers={"Content-Type": "application/x-ndjson"})
    SigV4Auth(creds, "aoss", AWS_REGION).add_auth(request)

    req = urllib.request.Request(url, data=payload, method="POST",
                                 headers=dict(request.headers))
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read())
        if result.get("errors"):
            logger.warning("Bulk index had errors: %s", json.dumps(result.get("items", [])[:3]))


def _send_to_dlq(failed: list, reason: str) -> None:
    """Write failed records to S3 DLQ bucket."""
    if not DLQ_BUCKET or not failed:
        return
    key = f"failed/{datetime.now(timezone.utc).strftime('%Y/%m/%d/%H%M%S')}-{reason[:40]}.json"
    s3.put_object(
        Bucket=DLQ_BUCKET,
        Key=key,
        Body=json.dumps({"reason": reason, "records": failed}).encode(),
        ContentType="application/json",
    )
    logger.info("Wrote %d failed records to s3://%s/%s", len(failed), DLQ_BUCKET, key)


def lambda_handler(event: dict, context: Any) -> dict:
    records   = event.get("Records", [])
    documents = []
    failed    = []

    logger.info("Processing %d Kinesis records", len(records))

    for record in records:
        try:
            raw_data = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
            raw      = json.loads(raw_data)
            doc      = _normalize_record(raw)

            # Build text for embedding: combine log line with metadata context
            embed_text = (
                f"[{doc['log_level']}] "
                f"namespace={doc['namespace']} pod={doc['pod']} container={doc['container']}: "
                f"{doc['log']}"
            )

            doc["embedding"] = _generate_embedding(embed_text)
            doc["embed_text"] = embed_text
            documents.append(doc)

        except Exception as exc:
            logger.warning("Failed to process record: %s", exc)
            failed.append({"record": record, "error": str(exc)})

    # Bulk index all successful documents
    if documents:
        try:
            _bulk_index(documents)
            logger.info("Indexed %d documents into OpenSearch", len(documents))
        except Exception as exc:
            logger.exception("Bulk index failed: %s", exc)
            _send_to_dlq(documents, f"bulk_index_failed: {exc}")
            failed.extend([{"doc": d, "error": str(exc)} for d in documents])

    if failed:
        _send_to_dlq(failed, "processing_errors")

    return {"statusCode": 200, "indexed": len(documents), "failed": len(failed)}
