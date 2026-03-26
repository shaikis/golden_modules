"""
Security Alert Enrichment Lambda Handler
=========================================
Processes security alert JSON files uploaded to the S3 input bucket.
  1. Reads alert JSON from S3.
  2. Loads few-shot examples from S3 examples bucket (cached in-memory).
  3. Calls Amazon Bedrock (Claude Tool Use) for structured alert enrichment:
       - alert_summary        — plain-language narrative for SOC analysts
       - risk_level           — CRITICAL / HIGH / MEDIUM / LOW / INFORMATIONAL
       - affected_resources   — IPs, ARNs, usernames, hostnames
       - attack_pattern       — MITRE ATT&CK tactic / technique
       - business_impact      — one-sentence impact statement
       - investigation_queries — ready-to-execute SQL / CloudWatch Logs queries
       - remediation_steps    — ordered, specific remediation actions
  4. Writes enriched JSON to S3 output bucket.
  5. Publishes SNS notification for CRITICAL / HIGH severity alerts.

Inspired by: https://aws.amazon.com/blogs/machine-learning/how-reco-transforms-security-alerts-using-amazon-bedrock/
"""

import json
import os
import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

bedrock    = boto3.client("bedrock-runtime")
s3         = boto3.client("s3")
sns_client = boto3.client("sns")

# In-memory cache — few-shot examples survive Lambda warm invocations
_FEW_SHOT_CACHE = None

# ---------------------------------------------------------------------------
# Claude Tool Use schema — forces Claude to return structured enrichment data
# ---------------------------------------------------------------------------
ENRICHMENT_TOOL = {
    "name": "enrich_security_alert",
    "description": (
        "Analyze a security alert and return a structured enrichment with a clear narrative "
        "summary, risk assessment, affected resources, attack pattern classification, "
        "business impact statement, ready-to-execute investigation queries, and "
        "prioritized remediation steps."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "alert_summary": {
                "type": "string",
                "description": (
                    "A concise, human-readable narrative (2-4 sentences) explaining "
                    "what happened, who/what is affected, and the likely attacker intent."
                )
            },
            "risk_level": {
                "type": "string",
                "enum": ["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL"],
                "description": "Overall risk/severity classification of the alert."
            },
            "affected_resources": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of affected resource identifiers (IPs, ARNs, usernames, hostnames)."
            },
            "attack_pattern": {
                "type": "string",
                "description": (
                    "MITRE ATT&CK tactic or technique that best describes the activity "
                    "(e.g. 'Credential Dumping', 'Lateral Movement', 'Data Exfiltration')."
                )
            },
            "business_impact": {
                "type": "string",
                "description": "One sentence describing potential business impact if not addressed."
            },
            "investigation_queries": {
                "type": "array",
                "items": {"type": "string"},
                "description": (
                    "3-5 ready-to-execute SQL / CloudWatch Logs Insights / Athena queries "
                    "the SOC analyst can run immediately to investigate further."
                )
            },
            "remediation_steps": {
                "type": "array",
                "items": {"type": "string"},
                "description": (
                    "Ordered list of specific remediation actions "
                    "(e.g. 'Revoke IAM access key AKIA...', 'Isolate EC2 instance i-...')."
                )
            },
            "confidence": {
                "type": "number",
                "description": "Model confidence in this enrichment between 0 and 1."
            }
        },
        "required": [
            "alert_summary",
            "risk_level",
            "affected_resources",
            "investigation_queries",
            "remediation_steps"
        ]
    }
}

SYSTEM_PROMPT = (
    "You are a senior cloud security analyst specializing in AWS threat detection "
    "and incident response. Your task is to analyze raw security alert data and "
    "transform it into actionable, human-readable enrichments.\n\n"
    "When analyzing alerts:\n"
    "- Identify the attacker intent and technique using MITRE ATT&CK framework\n"
    "- Assess impact on business operations, data confidentiality, and compliance\n"
    "- Generate specific, executable investigation queries relevant to the alert context\n"
    "- Provide prioritized, specific remediation steps (not generic advice)\n"
    "- Be concise but thorough — SOC analysts need to act quickly\n\n"
    "Risk levels:\n"
    "- CRITICAL: Active exploitation, confirmed breach, immediate action required\n"
    "- HIGH: Strong indicators of compromise, significant exposure\n"
    "- MEDIUM: Suspicious activity, policy violation, warrants investigation\n"
    "- LOW: Minor anomaly, policy deviation, low immediate risk\n"
    "- INFORMATIONAL: Baseline deviation, context useful for future investigations"
)


def _load_few_shot_examples() -> list:
    """Load few-shot examples from S3 (cached across warm Lambda invocations)."""
    global _FEW_SHOT_CACHE
    if _FEW_SHOT_CACHE is not None:
        return _FEW_SHOT_CACHE

    bucket = os.environ.get("EXAMPLES_BUCKET", "")
    key    = os.environ.get("EXAMPLES_KEY", "few-shot/examples.json")

    if not bucket:
        _FEW_SHOT_CACHE = []
        return _FEW_SHOT_CACHE

    try:
        obj = s3.get_object(Bucket=bucket, Key=key)
        _FEW_SHOT_CACHE = json.loads(obj["Body"].read().decode("utf-8"))
        logger.info("Loaded %d few-shot examples from s3://%s/%s", len(_FEW_SHOT_CACHE), bucket, key)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Could not load few-shot examples: %s — proceeding without them", exc)
        _FEW_SHOT_CACHE = []

    return _FEW_SHOT_CACHE


def _build_user_content(alert: dict, examples: list) -> str:
    """Build the user message with optional few-shot examples prepended."""
    parts = []

    if examples:
        parts.append(
            "Below are example security alert enrichments to guide your analysis "
            "style, depth, and output format:\n"
        )
        for i, ex in enumerate(examples[:3], 1):  # cap at 3 examples
            parts.append(f"--- Example {i} ---")
            parts.append(f"Alert:\n{json.dumps(ex.get('alert', {}), indent=2)}")
            parts.append(f"Expected enrichment:\n{json.dumps(ex.get('enrichment', {}), indent=2)}")
            parts.append("")
        parts.append("--- Alert to Analyze ---\n")

    parts.append(
        "Analyze this security alert and call the enrich_security_alert tool "
        "with your complete findings:\n\n"
        f"{json.dumps(alert, indent=2)}"
    )
    return "\n".join(parts)


def _enrich_with_bedrock(alert: dict, examples: list) -> dict:
    """Invoke Claude via Bedrock Tool Use and return structured enrichment."""
    guardrail_id      = os.environ.get("BEDROCK_GUARDRAIL_ID", "")
    guardrail_version = os.environ.get("BEDROCK_GUARDRAIL_VERSION", "DRAFT")

    invoke_kwargs = {
        "modelId": os.environ["CLAUDE_MODEL_ID"],
        "body": json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "system": SYSTEM_PROMPT,
            "tools": [ENRICHMENT_TOOL],
            "tool_choice": {"type": "tool", "name": "enrich_security_alert"},
            "messages": [
                {
                    "role": "user",
                    "content": _build_user_content(alert, examples)
                }
            ]
        })
    }

    if guardrail_id:
        invoke_kwargs["guardrailIdentifier"] = guardrail_id
        invoke_kwargs["guardrailVersion"]    = guardrail_version
        logger.info("Invoking Claude with guardrail %s:%s", guardrail_id, guardrail_version)
    else:
        logger.info("Invoking Claude without guardrail (enable_bedrock_guardrail = false)")

    response  = bedrock.invoke_model(**invoke_kwargs)
    resp_body = json.loads(response["body"].read())

    # Handle guardrail intervention
    if resp_body.get("amazon-bedrock-guardrailAction") == "GUARDRAIL_INTERVENED":
        logger.warning("Bedrock guardrail intervened — returning minimal safe enrichment")
        return {
            "alert_summary":        "Alert content blocked by content safety policy.",
            "risk_level":           "MEDIUM",
            "affected_resources":   [],
            "attack_pattern":       "Unknown",
            "business_impact":      "Manual review required.",
            "investigation_queries": ["Review alert content manually in the source system."],
            "remediation_steps":    ["Escalate to senior security analyst for manual review."],
            "confidence":           0.0,
            "guardrail_intervened": True,
        }

    for block in resp_body.get("content", []):
        if block.get("type") == "tool_use" and block.get("name") == "enrich_security_alert":
            return block["input"]

    logger.warning("No tool_use block found in Bedrock response")
    return {}


def _publish_sns_alert(enrichment: dict, source_key: str) -> None:
    """Publish SNS notification for CRITICAL or HIGH severity alerts."""
    topic_arn  = os.environ.get("SNS_ALERT_TOPIC_ARN", "")
    risk_level = enrichment.get("risk_level", "")

    if not topic_arn or risk_level not in ("CRITICAL", "HIGH"):
        return

    subject = f"[{risk_level}] Security Alert Requires Immediate Attention"
    message_lines = [
        f"Risk Level  : {risk_level}",
        f"Source Alert: {source_key}",
        "",
        "Summary:",
        enrichment.get("alert_summary", "N/A"),
        "",
        "Affected Resources:",
    ]
    for resource in enrichment.get("affected_resources", []):
        message_lines.append(f"  - {resource}")
    message_lines += [
        "",
        f"Attack Pattern: {enrichment.get('attack_pattern', 'N/A')}",
        "",
        "Business Impact:",
        enrichment.get("business_impact", "N/A"),
        "",
        "Top Remediation Steps:",
    ]
    for i, step in enumerate(enrichment.get("remediation_steps", [])[:3], 1):
        message_lines.append(f"  {i}. {step}")

    try:
        sns_client.publish(
            TopicArn=topic_arn,
            Subject=subject[:100],
            Message="\n".join(message_lines)
        )
        logger.info("SNS notification published for %s alert: %s", risk_level, source_key)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to publish SNS notification: %s", exc)


def lambda_handler(event, context):
    """SQS-triggered entry point. Each SQS record wraps an S3 event."""
    processed = 0
    errors    = 0

    # Load few-shot examples once per Lambda container (cached between warm invocations)
    examples = _load_few_shot_examples()

    for sqs_record in event.get("Records", []):
        try:
            s3_event = json.loads(sqs_record["body"])
            for s3_record in s3_event.get("Records", []):
                bucket = s3_record["s3"]["bucket"]["name"]
                key    = s3_record["s3"]["object"]["key"]

                logger.info("Processing alert s3://%s/%s", bucket, key)

                # ── Read alert JSON from S3 ─────────────────────────────
                obj   = s3.get_object(Bucket=bucket, Key=key)
                alert = json.loads(obj["Body"].read().decode("utf-8"))

                # ── Enrich alert with Bedrock Claude ────────────────────
                enrichment = _enrich_with_bedrock(alert, examples)
                logger.info(
                    "Alert enriched — risk_level=%s key=%s",
                    enrichment.get("risk_level", "UNKNOWN"), key
                )

                # ── Build full result payload ───────────────────────────
                result = {
                    "source_bucket":  bucket,
                    "source_key":     key,
                    "original_alert": alert,
                    "enrichment":     enrichment,
                }

                # ── Write enriched result to S3 output bucket ───────────
                out_key = (
                    key.replace("input/", "output/", 1)
                       .rsplit(".", 1)[0]
                    + "_enriched.json"
                )
                s3.put_object(
                    Bucket=os.environ["OUTPUT_BUCKET"],
                    Key=out_key,
                    Body=json.dumps(result, indent=2, default=str),
                    ContentType="application/json"
                )
                logger.info(
                    "Enriched result written to s3://%s/%s",
                    os.environ["OUTPUT_BUCKET"], out_key
                )

                # ── SNS notification for high-severity alerts ───────────
                _publish_sns_alert(enrichment, key)

                processed += 1

        except Exception as exc:  # noqa: BLE001
            logger.exception("Failed to process SQS record: %s", exc)
            errors += 1
            raise  # SQS retries then routes to DLQ

    return {
        "statusCode": 200,
        "processed":  processed,
        "errors":     errors,
    }
