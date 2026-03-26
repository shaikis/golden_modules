"""
RAG Chatbot Lambda
==================
Invoked directly (sync) by the Gradio UI or API Gateway.

Flow:
  1. Receive engineer query (e.g. "My pod is stuck in Pending state. Investigate.")
  2. Generate query embedding via Bedrock Titan Embed
  3. kNN search in OpenSearch to retrieve top-K semantically similar telemetry
  4. Build augmented prompt: query + retrieved telemetry context
  5. Call Claude LLM -> get list of kubectl commands to run
  6. Return kubectl commands to caller (Gradio UI / kubectl agent executes them)
  7. Optionally iterate: receive kubectl output, ask Claude if more investigation needed
  8. Return final root cause + resolution steps

The kubectl execution is done OUTSIDE this Lambda by a read-only agent
running inside the EKS cluster. This Lambda only generates the commands.
"""
import json
import logging
import os
from typing import Any

import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import urllib.request

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

bedrock = boto3.client("bedrock-runtime")
session = boto3.Session()

OPENSEARCH_ENDPOINT       = os.environ["OPENSEARCH_ENDPOINT"]
INDEX_NAME                = os.environ["INDEX_NAME"]
EMBEDDING_MODEL_ID        = os.environ["EMBEDDING_MODEL_ID"]
LLM_MODEL_ID              = os.environ["LLM_MODEL_ID"]
BEDROCK_GUARDRAIL_ID      = os.environ.get("BEDROCK_GUARDRAIL_ID", "")
BEDROCK_GUARDRAIL_VERSION = os.environ.get("BEDROCK_GUARDRAIL_VERSION", "DRAFT")
AWS_REGION                = os.environ.get("AWS_REGION", "us-east-1")

TOP_K               = 10    # number of telemetry chunks to retrieve
MAX_ITERATIONS      = 3     # max kubectl -> LLM cycles
MAX_TELEMETRY_CHARS = 8000  # truncate retrieved telemetry to fit in context


def _embed(text: str) -> list:
    resp = bedrock.invoke_model(
        modelId=EMBEDDING_MODEL_ID,
        body=json.dumps({"inputText": text[:8192]}),
        contentType="application/json",
        accept="application/json",
    )
    return json.loads(resp["body"].read())["embedding"]


def _os_search(query_vector: list, filters: dict = None) -> list:
    """kNN vector search in OpenSearch Serverless."""
    url  = f"{OPENSEARCH_ENDPOINT.rstrip('/')}/{INDEX_NAME}/_search"
    body = {
        "size": TOP_K,
        "query": {
            "knn": {
                "embedding": {
                    "vector": query_vector,
                    "k":      TOP_K,
                }
            }
        },
        "_source": ["timestamp", "log", "namespace", "pod", "container", "log_level", "embed_text"],
    }

    payload = json.dumps(body).encode()
    creds   = session.get_credentials().get_frozen_credentials()
    request = AWSRequest(method="POST", url=url, data=payload,
                         headers={"Content-Type": "application/json"})
    SigV4Auth(creds, "aoss", AWS_REGION).add_auth(request)

    req = urllib.request.Request(url, data=payload, method="POST",
                                 headers=dict(request.headers))
    with urllib.request.urlopen(req, timeout=30) as resp:
        result = json.loads(resp.read())

    hits = result.get("hits", {}).get("hits", [])
    return [h["_source"] for h in hits]


def _format_telemetry(hits: list) -> str:
    lines = []
    for h in hits:
        lines.append(
            f"[{h.get('timestamp','')}] "
            f"{h.get('namespace','?')}/{h.get('pod','?')} "
            f"[{h.get('log_level','INFO')}]: {h.get('log','')}"
        )
    return "\n".join(lines)[:MAX_TELEMETRY_CHARS]


def _call_claude(messages: list, system_prompt: str) -> str:
    invoke_kwargs = {
        "modelId":     LLM_MODEL_ID,
        "contentType": "application/json",
        "accept":      "application/json",
        "body": json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens":        2048,
            "system":            system_prompt,
            "messages":          messages,
        }),
    }

    if BEDROCK_GUARDRAIL_ID:
        invoke_kwargs["guardrailIdentifier"] = BEDROCK_GUARDRAIL_ID
        invoke_kwargs["guardrailVersion"]    = BEDROCK_GUARDRAIL_VERSION

    resp = bedrock.invoke_model(**invoke_kwargs)
    body = json.loads(resp["body"].read())
    return body["content"][0]["text"]


SYSTEM_PROMPT = """You are an expert Kubernetes and AWS troubleshooting assistant.
You help engineers diagnose and resolve issues in Amazon EKS clusters.

When given a query and relevant telemetry (logs, events, metrics):
1. Analyze the telemetry for error patterns, anomalies, and root causes
2. Generate specific, safe kubectl commands to investigate further
3. Format kubectl commands as a JSON list: {"commands": ["kubectl get pods -n <ns>", ...]}
4. Commands must be READ-ONLY: get, describe, logs, top -- NEVER delete, patch, apply, exec
5. When you have enough context, provide: root_cause, affected_resources, remediation_steps

Always respond with valid JSON in one of these formats:
- Investigation needed: {"action": "investigate", "commands": [...], "reasoning": "..."}
- Final answer: {"action": "resolve", "root_cause": "...", "affected_resources": [...], "remediation_steps": [...], "kubectl_commands": [...]}
"""


def lambda_handler(event: dict, context: Any) -> dict:
    """
    Expected input:
      {
        "query": "My pod is stuck in Pending state in namespace prod. Investigate.",
        "kubectl_output": "..."  # optional -- output from previous kubectl commands
        "iteration": 0           # optional -- current iteration count
      }
    """
    query          = event.get("query", "").strip()
    kubectl_output = event.get("kubectl_output", "")
    iteration      = int(event.get("iteration", 0))

    if not query:
        return {"statusCode": 400, "error": "query is required"}

    logger.info("Query (iteration %d): %s", iteration, query[:200])

    # 1. Embed query
    query_vector = _embed(query)

    # 2. Retrieve relevant telemetry from OpenSearch
    hits      = _os_search(query_vector)
    telemetry = _format_telemetry(hits)
    logger.info("Retrieved %d telemetry chunks from OpenSearch", len(hits))

    # 3. Build messages for Claude
    user_content = f"""Engineer query: {query}

Relevant telemetry from OpenSearch (most semantically similar logs):
---
{telemetry}
---
"""
    if kubectl_output:
        user_content += f"\nPrevious kubectl command output:\n---\n{kubectl_output}\n---\n"

    if iteration >= MAX_ITERATIONS:
        user_content += "\nThis is the final iteration. Provide your best resolution based on available evidence."

    messages = [{"role": "user", "content": user_content}]

    # 4. Call Claude
    response_text = _call_claude(messages, SYSTEM_PROMPT)
    logger.info("Claude response: %s", response_text[:500])

    # 5. Parse response
    try:
        response_json = json.loads(response_text)
    except json.JSONDecodeError:
        # Claude did not return valid JSON -- wrap it
        response_json = {"action": "resolve", "root_cause": response_text, "remediation_steps": []}

    return {
        "statusCode":     200,
        "query":          query,
        "iteration":      iteration,
        "response":       response_json,
        "telemetry_hits": len(hits),
    }
