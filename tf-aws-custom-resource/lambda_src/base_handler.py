"""
CloudFormation Custom Resource Base Handler
===========================================
Copy this file to your module's lambda_src/handler.py and implement the
_on_create, _on_update, and _on_delete functions for your use case.

The cfnresponse helper sends CREATE/SUCCESS or FAILED signals back to
CloudFormation so that Terraform knows when the resource is ready.

Lifecycle:
  terraform apply   ->  CloudFormation CREATE  ->  Lambda _on_create()
  terraform apply   ->  CloudFormation UPDATE  ->  Lambda _on_update()
  terraform destroy ->  CloudFormation DELETE  ->  Lambda _on_delete()

Returning data:
  Return a dict from _on_create / _on_update with the attributes you want
  to expose as outputs. These map to the output_attributes variable in
  the tf-aws-custom-resource module.

  Example:
    return {"AgentSpaceId": "abc-123", "AgentSpaceArn": "arn:aws:..."}
"""

import json
import logging
import os
import urllib.request

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ── cfnresponse helper ─────────────────────────────────────────────────────────
def _cfn_send(event, context, status, data=None, physical_id=None, reason=""):
    """Send a response to CloudFormation's pre-signed S3 URL."""
    response_url = event["ResponseURL"]
    response_body = {
        "Status":             status,
        "Reason":             reason or f"See CloudWatch log stream: {context.log_stream_name}",
        "PhysicalResourceId": physical_id or event.get("PhysicalResourceId") or context.log_stream_name,
        "StackId":            event["StackId"],
        "RequestId":          event["RequestId"],
        "LogicalResourceId":  event["LogicalResourceId"],
        "NoEcho":             False,
        "Data":               data or {},
    }
    body_bytes = json.dumps(response_body).encode("utf-8")
    req = urllib.request.Request(
        response_url,
        data=body_bytes,
        method="PUT",
        headers={
            "Content-Type":   "",   # Must be empty string for S3 pre-signed URL
            "Content-Length": str(len(body_bytes)),
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            logger.info("cfnresponse sent: status=%s http=%s", status, resp.status)
    except Exception as exc:
        logger.exception("Failed to send cfnresponse: %s", exc)


# ── Implement these three functions ───────────────────────────────────────────
def _on_create(props: dict) -> tuple[str, dict]:
    """
    Called on terraform apply (first time).

    Args:
        props: dict of properties from var.properties in the Terraform module.

    Returns:
        (physical_id, data_dict)
        - physical_id: A unique ID for this resource (used on update/delete).
        - data_dict:   Key/value pairs exposed as Terraform outputs via
                       output_attributes in the tf-aws-custom-resource module.

    Example for AWS DevOps Agent:
        client = boto3.client("devops-agent")
        resp = client.create_agent_space(
            agentSpaceName=props["AgentSpaceName"],
        )
        return resp["agentSpaceId"], {
            "AgentSpaceId":  resp["agentSpaceId"],
            "AgentSpaceArn": resp["agentSpaceArn"],
        }
    """
    raise NotImplementedError("Implement _on_create() for your use case.")


def _on_update(physical_id: str, props: dict, old_props: dict) -> dict:
    """
    Called on terraform apply when properties change.

    Args:
        physical_id: The ID returned by _on_create.
        props:       New properties.
        old_props:   Previous properties.

    Returns:
        data_dict -- same format as _on_create.
    """
    # Default: no-op update -- override if your resource supports updates
    logger.info("Update called for %s -- no-op", physical_id)
    return {}


def _on_delete(physical_id: str, props: dict) -> None:
    """
    Called on terraform destroy.

    Args:
        physical_id: The ID returned by _on_create.
        props:       Current properties.
    """
    raise NotImplementedError("Implement _on_delete() for your use case.")


# ── Lambda entrypoint ──────────────────────────────────────────────────────────
def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event, default=str))

    request_type = event.get("RequestType")
    props        = event.get("ResourceProperties", {})
    old_props    = event.get("OldResourceProperties", {})
    physical_id  = event.get("PhysicalResourceId", "")

    # Remove ServiceToken -- it's CFN metadata, not a real property
    props.pop("ServiceToken", None)
    old_props.pop("ServiceToken", None)

    try:
        if request_type == "Create":
            physical_id, data = _on_create(props)
            _cfn_send(event, context, "SUCCESS", data=data, physical_id=physical_id)

        elif request_type == "Update":
            data = _on_update(physical_id, props, old_props)
            _cfn_send(event, context, "SUCCESS", data=data, physical_id=physical_id)

        elif request_type == "Delete":
            _on_delete(physical_id, props)
            _cfn_send(event, context, "SUCCESS", physical_id=physical_id)

        else:
            raise ValueError(f"Unknown RequestType: {request_type}")

    except Exception as exc:
        logger.exception("Custom resource handler failed: %s", exc)
        _cfn_send(event, context, "FAILED", reason=str(exc), physical_id=physical_id or "FAILED")
