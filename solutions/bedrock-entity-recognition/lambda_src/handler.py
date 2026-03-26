"""
Bedrock Entity Recognition Lambda Handler
=========================================
Processes documents uploaded to the S3 input bucket.
  1. Reads document text from S3.
  2. Calls Amazon Bedrock (Claude Tool Use) for structured entity extraction.
  3. Optionally calls Amazon Comprehend for NLP baseline comparison.
  4. Writes merged results JSON to the S3 output bucket.
"""

import json
import os
import logging

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

bedrock    = boto3.client("bedrock-runtime")
s3         = boto3.client("s3")
comprehend = boto3.client("comprehend")

# ---------------------------------------------------------------------------
# Claude Tool Use schema — forces Claude to return structured entity data.
# ---------------------------------------------------------------------------
ENTITY_TOOL = {
    "name": "extract_entities",
    "description": "Extract all named entities from the provided text and return them in a structured format.",
    "input_schema": {
        "type": "object",
        "properties": {
            "entities": {
                "type": "array",
                "description": "List of named entities found in the text.",
                "items": {
                    "type": "object",
                    "properties": {
                        "text": {
                            "type": "string",
                            "description": "The exact surface form of the entity as it appears in the text."
                        },
                        "type": {
                            "type": "string",
                            "enum": ["PERSON", "ORGANIZATION", "LOCATION", "DATE", "QUANTITY", "OTHER"],
                            "description": "Semantic category of the entity."
                        },
                        "confidence": {
                            "type": "number",
                            "description": "Model confidence score between 0 and 1."
                        }
                    },
                    "required": ["text", "type"]
                }
            }
        },
        "required": ["entities"]
    }
}


def _extract_bedrock_entities(text: str) -> list:
    """Invoke Claude via Bedrock Tool Use and return structured entities.

    If BEDROCK_GUARDRAIL_ID is set (non-empty), the guardrail is applied to
    every invocation — Bedrock will anonymise PII and block harmful content
    before the response reaches this function.
    """
    guardrail_id      = os.environ.get("BEDROCK_GUARDRAIL_ID", "")
    guardrail_version = os.environ.get("BEDROCK_GUARDRAIL_VERSION", "DRAFT")

    invoke_kwargs = {
        "modelId": os.environ["CLAUDE_MODEL_ID"],
        "body": json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "tools": [ENTITY_TOOL],
            "tool_choice": {"type": "tool", "name": "extract_entities"},
            "messages": [
                {
                    "role": "user",
                    "content": (
                        "Extract all named entities from the text below. "
                        "Return every person, organisation, location, date, and quantity you find.\n\n"
                        f"{text}"
                    )
                }
            ]
        })
    }

    # Attach guardrail when one is configured via Terraform.
    # The guardrail filters PII and harmful content BEFORE the response is returned.
    if guardrail_id:
        invoke_kwargs["guardrailIdentifier"] = guardrail_id
        invoke_kwargs["guardrailVersion"]    = guardrail_version
        logger.info("Invoking Claude with guardrail %s:%s", guardrail_id, guardrail_version)
    else:
        logger.info("Invoking Claude without guardrail (enable_bedrock_guardrail = false)")

    response  = bedrock.invoke_model(**invoke_kwargs)
    resp_body = json.loads(response["body"].read())

    # Check if the guardrail blocked the response
    if resp_body.get("amazon-bedrock-guardrailAction") == "GUARDRAIL_INTERVENED":
        logger.warning("Bedrock guardrail intervened on response — returning empty entity list")
        return []

    for block in resp_body.get("content", []):
        if block.get("type") == "tool_use" and block.get("name") == "extract_entities":
            return block["input"].get("entities", [])
    return []


def _extract_comprehend_entities(text: str) -> list:
    """Call Amazon Comprehend DetectEntities and return the raw entity list."""
    # Comprehend accepts up to 5 000 UTF-8 bytes; truncate gracefully.
    truncated = text[:5000]
    resp = comprehend.detect_entities(
        Text=truncated,
        LanguageCode=os.environ.get("COMPREHEND_LANGUAGE_CODE", "en")
    )
    return resp.get("Entities", [])


def lambda_handler(event, context):
    """SQS-triggered entry point.  Each SQS record wraps an S3 event."""
    processed = 0
    errors     = 0

    for sqs_record in event.get("Records", []):
        try:
            s3_event = json.loads(sqs_record["body"])
            for s3_record in s3_event.get("Records", []):
                bucket = s3_record["s3"]["bucket"]["name"]
                key    = s3_record["s3"]["object"]["key"]

                logger.info("Processing s3://%s/%s", bucket, key)

                # ── Read document from S3 ──────────────────────────────────
                obj  = s3.get_object(Bucket=bucket, Key=key)
                text = obj["Body"].read().decode("utf-8")

                result = {
                    "source_bucket":       bucket,
                    "source_key":          key,
                    "bedrock_entities":    [],
                    "comprehend_entities": [],
                }

                # ── Bedrock Claude Tool Use ────────────────────────────────
                result["bedrock_entities"] = _extract_bedrock_entities(text)
                logger.info(
                    "Bedrock found %d entities for %s",
                    len(result["bedrock_entities"]), key
                )

                # ── Amazon Comprehend (optional comparison) ────────────────
                if os.environ.get("ENABLE_COMPREHEND", "true").lower() == "true":
                    result["comprehend_entities"] = _extract_comprehend_entities(text)
                    logger.info(
                        "Comprehend found %d entities for %s",
                        len(result["comprehend_entities"]), key
                    )

                # ── Persist results to S3 output bucket ────────────────────
                out_key = (
                    key.replace("input/", "output/", 1)
                       .rsplit(".", 1)[0]
                    + "_entities.json"
                )
                s3.put_object(
                    Bucket=os.environ["OUTPUT_BUCKET"],
                    Key=out_key,
                    Body=json.dumps(result, indent=2, default=str),
                    ContentType="application/json"
                )
                logger.info("Results written to s3://%s/%s", os.environ["OUTPUT_BUCKET"], out_key)
                processed += 1

        except Exception as exc:  # noqa: BLE001
            logger.exception("Failed to process SQS record: %s", exc)
            errors += 1
            # Re-raise so SQS marks the message as failed and routes it to the DLQ
            raise

    return {
        "statusCode": 200,
        "processed":  processed,
        "errors":     errors,
    }
