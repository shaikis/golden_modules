# =============================================================================
# SCENARIO: DevSecOps CI/CD Pipeline Container Security
#
# A DevOps team wants to shift-left security by scanning container images
# as part of their CI/CD pipeline. ECR Inspector findings gate deployments:
#   - Enable ECR scanning only (no EC2 needed for this pattern)
#   - HIGH/CRITICAL findings trigger SNS → Lambda → fail the pipeline
#   - Suppress known acceptable CVEs in base images (OS-level, not app-level)
#   - Lambda scanning for serverless microservices
#   - Export findings to S3 for audit trail / compliance reporting
# =============================================================================

provider "aws" { region = var.aws_region }

# ─── SNS Topic: pipeline security gate ─────────────────────────────────────
resource "aws_sns_topic" "pipeline_gate" {
  name = "${var.name}-pipeline-security-gate"
}

# ─── Lambda: evaluate findings and fail CodePipeline on HIGH/CRITICAL ───────
resource "aws_iam_role" "gate_lambda" {
  name = "${var.name}-pipeline-gate-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gate_lambda_basic" {
  role       = aws_iam_role.gate_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "gate_lambda_codepipeline" {
  name = "codepipeline-stop"
  role = aws_iam_role.gate_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["codepipeline:StopPipelineExecution", "codepipeline:PutJobFailureResult"]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "pipeline_gate" {
  function_name = "${var.name}-pipeline-security-gate"
  role          = aws_iam_role.gate_lambda.arn
  runtime       = "python3.12"
  handler       = "index.handler"
  timeout       = 30

  # Inline ZIP — in production, use S3 or container image
  filename         = data.archive_file.gate_lambda.output_path
  source_code_hash = data.archive_file.gate_lambda.output_base64sha256

  environment {
    variables = {
      PIPELINE_NAME = var.pipeline_name
    }
  }
}

data "archive_file" "gate_lambda" {
  type        = "zip"
  output_path = "/tmp/pipeline_gate.zip"
  source {
    content  = <<-PYTHON
      import boto3, os, json

      def handler(event, context):
          """
          Triggered by SNS when Inspector finds HIGH/CRITICAL CVE in ECR image.
          Stops the named CodePipeline execution to prevent vulnerable image deploy.
          """
          pipeline = os.environ["PIPELINE_NAME"]
          cp = boto3.client("codepipeline")

          for record in event.get("Records", []):
              finding = json.loads(record["Sns"]["Message"])
              severity = finding.get("detail", {}).get("severity", "")
              image_tags = finding.get("detail", {}).get("resources", [{}])[0].get("details", {}).get("awsEcrContainerImage", {}).get("imageTags", [])

              print(f"Blocking pipeline {pipeline} — severity={severity} tags={image_tags}")

              executions = cp.list_pipeline_executions(pipelineName=pipeline, maxResults=1)
              for exe in executions.get("pipelineExecutionSummaries", []):
                  if exe["status"] == "InProgress":
                      cp.stop_pipeline_execution(
                          pipelineName=pipeline,
                          pipelineExecutionId=exe["pipelineExecutionId"],
                          abandon=True,
                          reason=f"Inspector found {severity} CVE in container image"
                      )
          return {"statusCode": 200}
    PYTHON
    filename = "index.py"
  }
}

# Wire SNS → Lambda
resource "aws_sns_topic_subscription" "gate_lambda" {
  topic_arn = aws_sns_topic.pipeline_gate.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.pipeline_gate.arn
}

resource "aws_lambda_permission" "sns_invoke_gate" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pipeline_gate.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.pipeline_gate.arn
}

# ─── S3 bucket for compliance audit trail ────────────────────────────────────
resource "aws_s3_bucket" "findings_audit" {
  bucket        = "${var.name}-inspector-findings-audit"
  force_destroy = true
}

# ─── Inspector module ─────────────────────────────────────────────────────────
module "inspector" {
  source      = "../../"
  name        = "devsecops"
  name_prefix = var.name
  environment = var.environment
  project     = var.project
  owner       = var.owner
  cost_center = var.cost_center

  # Only ECR + Lambda — EC2 not part of this pattern
  enable_ec2_scanning         = false
  enable_ecr_scanning         = true
  enable_lambda_scanning      = true
  enable_lambda_code_scanning = true

  # Gate CodePipeline on HIGH/CRITICAL ECR findings
  enable_findings_notifications = true
  findings_sns_topic_arn        = aws_sns_topic.pipeline_gate.arn
  findings_severity_filter      = ["HIGH", "CRITICAL"]

  # Compliance audit export
  enable_findings_export      = true
  findings_export_bucket_name = aws_s3_bucket.findings_audit.bucket

  # Suppress base OS image CVEs — app team is not responsible for OS patches
  # The platform team manages AMI/base image hardening separately
  suppression_rules = [
    {
      name        = "base-os-ncurses-accepted"
      description = "ncurses CVE in Alpine base image — no fix available, accepted risk (Risk-2024-112)"
      reason      = "ACCEPTED_RISK"
      filters = [
        {
          vulnerability_id = ["CVE-2023-29491"]
          resource_type    = ["AWS_ECR_CONTAINER_IMAGE"]
          severity         = ["MEDIUM"]
        }
      ]
    },
    {
      name        = "zlib-false-positive"
      description = "zlib CVE false-positive — our Alpine version includes backport patch"
      reason      = "FALSE_POSITIVE"
      filters = [
        {
          vulnerability_id = ["CVE-2022-37434"]
          resource_type    = ["AWS_ECR_CONTAINER_IMAGE"]
        }
      ]
    }
  ]
}

output "enabled_resource_types"    { value = module.inspector.enabled_resource_types }
output "findings_event_rule_arn"   { value = module.inspector.findings_event_rule_arn }
output "pipeline_gate_lambda_arn"  { value = aws_lambda_function.pipeline_gate.arn }
output "findings_audit_bucket"     { value = aws_s3_bucket.findings_audit.bucket }
