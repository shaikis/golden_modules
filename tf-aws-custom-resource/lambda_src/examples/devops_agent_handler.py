"""
Example: AWS DevOps Agent -- Agent Space Custom Resource Handler
===============================================================
This handler manages an AWS DevOps Agent Space lifecycle via boto3.
Deploy using tf-aws-custom-resource module.

Required var.properties in Terraform:
  AgentSpaceName  = var.name
  EksClusterArn   = module.eks.cluster_arn
  PrometheusArn   = module.amp.workspace_arn
  Region          = var.aws_region

Required var.output_attributes in Terraform:
  agent_space_id  = "AgentSpaceId"

Required IAM permissions (add to additional_policy_statements):
  devops-agent:CreateAgentSpace
  devops-agent:DeleteAgentSpace
  devops-agent:GetAgentSpace
  devops-agent:AssociateDataSource
"""

import json
import logging
import time
import urllib.request

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _cfn_send(event, context, status, data=None, physical_id=None, reason=""):
    response_url  = event["ResponseURL"]
    response_body = {
        "Status":             status,
        "Reason":             reason or f"See log stream: {context.log_stream_name}",
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
        headers={"Content-Type": "", "Content-Length": str(len(body_bytes))},
    )
    with urllib.request.urlopen(req, timeout=30):
        pass


def _wait_for_active(client, agent_space_id: str, max_wait: int = 300):
    """Poll until Agent Space status is ACTIVE."""
    deadline = time.time() + max_wait
    while time.time() < deadline:
        resp   = client.get_agent_space(agentSpaceId=agent_space_id)
        status = resp["agentSpace"]["status"]
        logger.info("Agent Space %s status: %s", agent_space_id, status)
        if status == "ACTIVE":
            return
        if status == "FAILED":
            raise RuntimeError(f"Agent Space creation failed: {resp}")
        time.sleep(15)
    raise TimeoutError(f"Agent Space {agent_space_id} did not become ACTIVE within {max_wait}s")


def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event, default=str))

    request_type = event.get("RequestType")
    props        = event.get("ResourceProperties", {})
    props.pop("ServiceToken", None)
    physical_id  = event.get("PhysicalResourceId", "")

    client = boto3.client("devops-agent", region_name=props.get("Region", "us-east-1"))

    try:
        if request_type == "Create":
            resp = client.create_agent_space(
                agentSpaceName=props["AgentSpaceName"],
            )
            agent_space_id = resp["agentSpace"]["agentSpaceId"]

            # Wait for ACTIVE
            _wait_for_active(client, agent_space_id)

            # Associate data sources
            if props.get("PrometheusArn"):
                client.associate_data_source(
                    agentSpaceId=agent_space_id,
                    dataSourceArn=props["PrometheusArn"],
                )
            if props.get("EksClusterArn"):
                client.associate_data_source(
                    agentSpaceId=agent_space_id,
                    dataSourceArn=props["EksClusterArn"],
                )

            _cfn_send(event, context, "SUCCESS",
                      data={"AgentSpaceId": agent_space_id},
                      physical_id=agent_space_id)

        elif request_type == "Update":
            # Agent Space does not support name changes -- no-op
            _cfn_send(event, context, "SUCCESS", physical_id=physical_id)

        elif request_type == "Delete":
            if physical_id and physical_id != "FAILED":
                try:
                    client.delete_agent_space(agentSpaceId=physical_id)
                    logger.info("Deleted Agent Space: %s", physical_id)
                except client.exceptions.ResourceNotFoundException:
                    logger.warning("Agent Space %s already deleted", physical_id)
            _cfn_send(event, context, "SUCCESS", physical_id=physical_id)

    except Exception as exc:
        logger.exception("Handler failed: %s", exc)
        _cfn_send(event, context, "FAILED", reason=str(exc),
                  physical_id=physical_id or "FAILED")
