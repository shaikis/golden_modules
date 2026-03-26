# ── Example: AWS DevOps Agent provisioned via Custom Resource ──────────────────
# This pattern works for ANY AWS service not yet supported by the Terraform
# AWS provider. Replace the Lambda handler with your specific API calls.

locals {
  prefix = "${var.name}-${var.environment}"
}

# IAM role for the custom resource Lambda -- add DevOps Agent permissions
module "cr_lambda_role" {
  source = "../../../tf-aws-iam-role"

  name        = "${local.prefix}-devops-agent-cr"
  environment = var.environment
  tags        = var.tags

  trusted_role_services = ["lambda.amazonaws.com"]
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policies = {
    "devops-agent-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "DevOpsAgentManage"
          Effect = "Allow"
          Action = [
            "devops-agent:CreateAgentSpace",
            "devops-agent:DeleteAgentSpace",
            "devops-agent:GetAgentSpace",
            "devops-agent:AssociateDataSource",
            "devops-agent:DisassociateDataSource",
          ]
          Resource = "*"
        },
        {
          Sid    = "PassRoleForAgent"
          Effect = "Allow"
          Action = ["iam:PassRole"]
          Resource = "*"
          Condition = {
            StringEquals = { "iam:PassedToService" = "devops-agent.amazonaws.com" }
          }
        }
      ]
    })
  }
}

# The custom resource module -- wraps Lambda + CloudFormation Custom Resource
module "devops_agent" {
  source = "../../../tf-aws-custom-resource"

  name          = "${local.prefix}-devops-agent"
  environment   = var.environment
  tags          = var.tags
  resource_type = "DevOpsAgentSpace"

  create_lambda   = true
  lambda_role_arn = module.cr_lambda_role.role_arn
  timeout         = 300

  # Properties passed to the Lambda on Create/Update/Delete
  properties = {
    AgentSpaceName = local.prefix
    EksClusterArn  = var.eks_cluster_arn
    PrometheusArn  = var.prometheus_workspace_arn
    Region         = var.aws_region
  }

  # Lambda returns AgentSpaceId -- expose as Terraform output
  output_attributes = {
    agent_space_id = "AgentSpaceId"
  }

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # Force re-run when EKS cluster or Prometheus workspace changes
  trigger_on_change = sha256("${var.eks_cluster_arn}${var.prometheus_workspace_arn}")
}

output "agent_space_id" {
  description = "AWS DevOps Agent Space ID."
  value       = module.devops_agent.stack_outputs["agent_space_id"]
}
