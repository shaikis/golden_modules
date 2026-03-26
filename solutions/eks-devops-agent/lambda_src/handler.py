"""
AWS DevOps Agent Space -- CloudFormation Custom Resource Handler
================================================================
Manages the full lifecycle (Create / Update / Delete) of an AWS DevOps
Agent Space and its data source associations.

This file is standalone: the _cfn_send helper is included inline so no
external cfnresponse layer is required.

Required var.properties in the calling Terraform module:
  AgentSpaceName  = "<name>"
  EksClusterArn   = "<arn>"
  PrometheusArn   = "<arn>"
  Region          = "<aws-region>"

Required var.output_attributes:
  agent_space_id  = "AgentSpaceId"

Required IAM permissions on the Lambda execution role:
  devops-agent:CreateAgentSpace
  devops-agent:DeleteAgentSpace
  devops-agent:GetAgentSpace
  devops-agent:AssociateDataSource
  devops-agent:DisassociateDataSource
"""

import json
import logging
import time
import urllib.request

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ---------------------------------------------------------------------------
# CloudFormation response helper (inline — no cfnresponse layer required)
# ---------------------------------------------------------------------------

def _cfn_send(event, context, status, data=None, physical_id=None, reason=""):
    """Signal CloudFormation with the result of a custom resource operation."""
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
            "Content-Type":   "",
            "Content-Length": str(len(body_bytes)),
        },
    )
    with urllib.request.urlopen(req, timeout=30):
        pass
    logger.info("cfnresponse sent: status=%s physical_id=%s", status, response_body["PhysicalResourceId"])


# ---------------------------------------------------------------------------
# Polling helper
# ---------------------------------------------------------------------------

def _wait_for_active(client, agent_space_id: str, max_wait: int = 300):
    """Poll the Agent Space until its status is ACTIVE or FAILED."""
    deadline = time.time() + max_wait
    while time.time() < deadline:
        resp   = client.get_agent_space(agentSpaceId=agent_space_id)
        status = resp["agentSpace"]["status"]
        logger.info("Agent Space %s status: %s", agent_space_id, status)
        if status == "ACTIVE":
            return
        if status == "FAILED":
            raise RuntimeError(f"Agent Space entered FAILED state: {json.dumps(resp, default=str)}")
        time.sleep(15)
    raise TimeoutError(
        f"Agent Space {agent_space_id} did not reach ACTIVE within {max_wait}s"
    )


# ---------------------------------------------------------------------------
# Lambda entry point
# ---------------------------------------------------------------------------

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event, default=str))

    request_type = event.get("RequestType")
    props        = event.get("ResourceProperties", {})
    props.pop("ServiceToken", None)          # injected by CloudFormation, not needed
    physical_id  = event.get("PhysicalResourceId", "")

    region = props.get("Region", "us-east-1")
    client = boto3.client("devops-agent", region_name=region)

    try:
        # ------------------------------------------------------------------
        # CREATE — provision a new Agent Space and attach data sources
        # ------------------------------------------------------------------
        if request_type == "Create":
            logger.info("Creating Agent Space: %s", props.get("AgentSpaceName"))

            resp = client.create_agent_space(
                agentSpaceName=props["AgentSpaceName"],
            )
            agent_space_id = resp["agentSpace"]["agentSpaceId"]
            logger.info("Created Agent Space: %s", agent_space_id)

            # Wait until ACTIVE before associating data sources
            _wait_for_active(client, agent_space_id)

            # Associate AMP workspace as a Prometheus data source
            if props.get("PrometheusArn"):
                logger.info("Associating AMP workspace: %s", props["PrometheusArn"])
                client.associate_data_source(
                    agentSpaceId=agent_space_id,
                    dataSourceArn=props["PrometheusArn"],
                )

            # Associate EKS cluster for topology and resource discovery
            if props.get("EksClusterArn"):
                logger.info("Associating EKS cluster: %s", props["EksClusterArn"])
                client.associate_data_source(
                    agentSpaceId=agent_space_id,
                    dataSourceArn=props["EksClusterArn"],
                )

            _cfn_send(
                event, context, "SUCCESS",
                data={"AgentSpaceId": agent_space_id},
                physical_id=agent_space_id,
            )

        # ------------------------------------------------------------------
        # UPDATE — Agent Space name and ARN associations are immutable;
        #          signal success without making any API calls.
        # ------------------------------------------------------------------
        elif request_type == "Update":
            logger.info("Update is a no-op for Agent Space %s", physical_id)
            _cfn_send(event, context, "SUCCESS", physical_id=physical_id)

        # ------------------------------------------------------------------
        # DELETE — delete the Agent Space; tolerate already-deleted resources
        # ------------------------------------------------------------------
        elif request_type == "Delete":
            if physical_id and physical_id not in ("", "FAILED"):
                try:
                    logger.info("Deleting Agent Space: %s", physical_id)
                    client.delete_agent_space(agentSpaceId=physical_id)
                    logger.info("Deleted Agent Space: %s", physical_id)
                except client.exceptions.ResourceNotFoundException:
                    logger.warning(
                        "Agent Space %s not found — already deleted or never created.",
                        physical_id,
                    )
            else:
                logger.info("No valid physical_id — nothing to delete.")

            _cfn_send(event, context, "SUCCESS", physical_id=physical_id or "DELETED")

        else:
            raise ValueError(f"Unknown RequestType: {request_type!r}")

    except Exception as exc:
        logger.exception("Handler failed with error: %s", exc)
        _cfn_send(
            event, context, "FAILED",
            reason=str(exc),
            physical_id=physical_id or "FAILED",
        )
