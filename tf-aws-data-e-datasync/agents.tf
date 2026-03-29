# =============================================================================
# DataSync Agents
#
# Two operating modes controlled by var.auto_activate_agents:
#
# Mode A — BYO activation key (auto_activate_agents = false, default):
#   Caller provides activation_key obtained manually from the AWS console
#   or their own automation.  Module simply calls aws_datasync_agent.
#
# Mode B — Fully automated (auto_activate_agents = true):
#   1. EC2 instance launched from the DataSync agent AMI
#   2. Private IP stored in SSM Parameter Store
#   3. Lambda function invoked:
#        a. Polls agent port 80 to retrieve the one-time activation key
#        b. Calls datasync:CreateAgent to register the agent
#        c. Stores the resulting agent ARN in SSM Parameter Store
#   4. Terraform reads the activation key back from the Lambda result
#      and creates the aws_datasync_agent resource (idempotent import)
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  auto_agents = var.create_agents && var.auto_activate_agents ? var.agents : {}
  byo_agents  = var.create_agents && !var.auto_activate_agents ? var.agents : {}
}

# ---------------------------------------------------------------------------
# Mode B — EC2 instances
# ---------------------------------------------------------------------------
resource "aws_instance" "agent" {
  for_each = local.auto_agents

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.ec2_security_group_ids
  iam_instance_profile   = each.value.iam_instance_profile
  key_name               = each.value.key_name
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 80
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, each.value.tags, {
    Name = "datasync-agent-${each.key}"
    Role = "datasync-agent"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# Store private IP in SSM so the Lambda can look it up
resource "aws_ssm_parameter" "agent_ip" {
  for_each = local.auto_agents

  name  = "/datasync/${var.name_prefix}${each.key}/private-ip"
  type  = "String"
  value = aws_instance.agent[each.key].private_ip
  tags  = merge(var.tags, { Purpose = "datasync-agent-activation" })
}

# ---------------------------------------------------------------------------
# Mode B — IAM role for the activation Lambda
# ---------------------------------------------------------------------------
resource "aws_iam_role" "activation_lambda" {
  count = var.auto_activate_agents && length(local.auto_agents) > 0 ? 1 : 0
  name  = "${var.name_prefix}datasync-activation-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  tags = var.tags
}

resource "aws_iam_role_policy" "activation_lambda" {
  count = var.auto_activate_agents && length(local.auto_agents) > 0 ? 1 : 0
  name  = "${var.name_prefix}datasync-activation-lambda"
  role  = aws_iam_role.activation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DataSyncCreateAgent"
        Effect = "Allow"
        Action = ["datasync:CreateAgent", "datasync:DescribeAgent", "datasync:TagResource"]
        Resource = "*"
      },
      {
        Sid    = "SSMParameterStore"
        Effect = "Allow"
        Action = ["ssm:GetParameter", "ssm:PutParameter"]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/datasync/*"
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Mode B — activation Lambda (inline Python, packaged at plan time)
# ---------------------------------------------------------------------------
data "archive_file" "activation_lambda" {
  count       = var.auto_activate_agents && length(local.auto_agents) > 0 ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/.activation_lambda.zip"

  source {
    filename = "index.py"
    content  = <<-PYTHON
      import boto3, urllib.request, urllib.parse, json, time, os

      def handler(event, context):
          agent_ip    = event['agent_ip']
          agent_name  = event['agent_name']
          agent_key   = event['agent_key']
          region      = event['region']
          ssm_param   = event['ssm_param']
          pl_endpoint = event.get('private_link_endpoint')
          tags        = event.get('tags', [])

          # ── Step 1: fetch activation key from the agent's HTTP server ──────
          params = {'gatewayType': 'SYNC', 'activationRegion': region, 'no_redirect': ''}
          if pl_endpoint:
              params.update({'endpointType': 'PRIVATE_LINK', 'privateLinkEndpoint': pl_endpoint})
          url = 'http://{}/?{}'.format(agent_ip, urllib.parse.urlencode(params))

          activation_key = None
          for attempt in range(24):          # up to 6 minutes
              try:
                  with urllib.request.urlopen(url, timeout=10) as r:
                      body = r.read().decode()
                  if 'activationKey=' in body:
                      activation_key = body.split('activationKey=')[1].split('&')[0].split('"')[0]
                      break
              except Exception as exc:
                  print(f'Attempt {attempt+1}/24: {exc}')
                  time.sleep(15)

          if not activation_key:
              raise RuntimeError(f'Could not get activation key from {agent_ip} after 6 minutes')

          # ── Step 2: register the agent ────────────────────────────────────
          ds = boto3.client('datasync', region_name=region)
          resp = ds.create_agent(ActivationKey=activation_key, AgentName=agent_name, Tags=tags)
          agent_arn = resp['AgentArn']

          # ── Step 3: persist ARN in SSM Parameter Store ────────────────────
          ssm = boto3.client('ssm', region_name=region)
          ssm.put_parameter(Name=ssm_param, Value=agent_arn, Type='String', Overwrite=True)

          print(f'Agent {agent_key} registered: {agent_arn}')
          return {'agent_arn': agent_arn, 'activation_key': activation_key}
    PYTHON
  }
}

resource "aws_lambda_function" "activation" {
  for_each = local.auto_agents

  function_name    = "${var.name_prefix}datasync-activate-${each.key}"
  role             = aws_iam_role.activation_lambda[0].arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = var.activation_lambda_timeout
  memory_size      = 256
  filename         = data.archive_file.activation_lambda[0].output_path
  source_code_hash = data.archive_file.activation_lambda[0].output_base64sha256

  vpc_config {
    subnet_ids         = var.activation_lambda_subnet_ids
    security_group_ids = var.activation_lambda_security_group_ids
  }

  tags = merge(var.tags, { Purpose = "datasync-agent-activation", AgentKey = each.key })

  depends_on = [aws_ssm_parameter.agent_ip]
}

# Invoke the Lambda synchronously — waits for agent registration to complete
resource "aws_lambda_invocation" "activation" {
  for_each = local.auto_agents

  function_name = aws_lambda_function.activation[each.key].function_name

  input = jsonencode({
    agent_ip              = aws_instance.agent[each.key].private_ip
    agent_name            = coalesce(each.value.name, each.key)
    agent_key             = each.key
    region                = coalesce(each.value.activation_region, data.aws_region.current.name)
    ssm_param             = "/datasync/${var.name_prefix}${each.key}/arn"
    private_link_endpoint = each.value.private_link_endpoint
    tags = [
      for k, v in merge(var.tags, each.value.tags, { Name = coalesce(each.value.name, each.key) }) :
      { Key = k, Value = v }
    ]
  })

  # Re-trigger only if the EC2 instance is replaced
  triggers = { instance_id = aws_instance.agent[each.key].id }
}

# Read agent ARN from SSM (written by the Lambda)
data "aws_ssm_parameter" "agent_arn" {
  for_each = local.auto_agents

  name       = "/datasync/${var.name_prefix}${each.key}/arn"
  depends_on = [aws_lambda_invocation.activation]
}

# ---------------------------------------------------------------------------
# aws_datasync_agent — both modes converge here
# ---------------------------------------------------------------------------
resource "aws_datasync_agent" "this" {
  for_each = var.create_agents ? var.agents : {}

  name            = coalesce(each.value.name, each.key)
  vpc_endpoint_id = each.value.vpc_endpoint_id
  subnet_arns     = each.value.subnet_arns
  security_group_arns = each.value.security_group_arns

  # Mode A: caller provides activation_key directly
  # Mode B: activation_key comes from the Lambda invocation result
  activation_key = var.auto_activate_agents ? (
    jsondecode(aws_lambda_invocation.activation[each.key].result)["activation_key"]
  ) : each.value.activation_key

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, each.key)
  })

  lifecycle {
    # Activation is one-time; prevent Terraform from re-activating on plan drift
    ignore_changes = [activation_key, ip_address]
  }

  depends_on = [aws_lambda_invocation.activation]
}
