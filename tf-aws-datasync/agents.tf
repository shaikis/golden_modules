# =============================================================================
# DataSync Agent — EC2 + Automated Activation
#
# Activation flow:
#   1. Launch EC2 with the DataSync agent AMI
#   2. Store the instance's private IP in SSM Parameter Store
#   3. Lambda polls the agent's built-in HTTP server (port 80) to retrieve
#      the one-time activation key
#   4. Lambda calls datasync:CreateAgent with the key and stores the agent
#      ARN back in SSM Parameter Store
#   5. Terraform reads the agent ARN from SSM and creates the Terraform
#      aws_datasync_agent resource (import-by-ARN via the activation_key
#      output from the Lambda)
# =============================================================================

# ---------------------------------------------------------------------------
# IAM role for the activation Lambda
# ---------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "activation_lambda" {
  count = length(var.agents) > 0 ? 1 : 0
  name  = "${local.name}-datasync-activation"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "activation_lambda" {
  count = length(var.agents) > 0 ? 1 : 0
  name  = "${local.name}-datasync-activation"
  role  = aws_iam_role.activation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DataSyncAgentCreate"
        Effect = "Allow"
        Action = [
          "datasync:CreateAgent",
          "datasync:DescribeAgent",
          "datasync:ListAgents",
          "datasync:TagResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMParameterReadWrite"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:AddTagsToResource",
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/datasync/*"
      },
      {
        Sid    = "EC2DescribeForAgentIP"
        Effect = "Allow"
        Action = ["ec2:DescribeInstances", "ec2:DescribeNetworkInterfaces"]
        Resource = "*"
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Agent EC2 instances
# ---------------------------------------------------------------------------
resource "aws_instance" "agent" {
  for_each = var.agents

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.security_group_ids
  iam_instance_profile   = each.value.iam_instance_profile
  key_name               = each.value.key_name

  # DataSync agent needs SSM for management and must reach DataSync endpoints
  # Do NOT assign public IP for private-link or VPC-internal agents
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 80
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.tags, each.value.additional_tags, {
    Name = "datasync-agent-${each.key}"
    Role = "datasync-agent"
  })

  lifecycle {
    ignore_changes = [ami]  # avoid replacing agent on AMI updates
  }
}

# ---------------------------------------------------------------------------
# Store agent private IP in SSM for the activation Lambda
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "agent_ip" {
  for_each = var.agents

  name  = "/datasync/${local.name}/agents/${each.key}/private-ip"
  type  = "String"
  value = aws_instance.agent[each.key].private_ip

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Activation Lambda — one per agent
# Inline Python: polls agent HTTP endpoint → calls datasync:CreateAgent →
# writes agent ARN to SSM
# ---------------------------------------------------------------------------
data "archive_file" "activation_lambda" {
  count       = length(var.agents) > 0 ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/activation_lambda.zip"

  source {
    content  = <<-PYTHON
      import boto3, urllib.request, urllib.parse, os, json, time

      def handler(event, context):
          agent_ip        = event['agent_ip']
          agent_name      = event['agent_name']
          agent_key       = event['agent_key']      # logical key (map key)
          region          = event['region']
          ssm_param       = event['ssm_param']
          private_link_ep = event.get('private_link_endpoint', None)
          tags            = event.get('tags', [])

          # Step 1: fetch activation key from agent's built-in HTTP server
          params = urllib.parse.urlencode({
              'gatewayType': 'SYNC',
              'activationRegion': region,
              'no_redirect': '',
              **(({'endpointType': 'PRIVATE_LINK', 'privateLinkEndpoint': private_link_ep}
                  if private_link_ep else {}))
          })
          url = f'http://{agent_ip}/?{params}'

          activation_key = None
          for attempt in range(20):
              try:
                  with urllib.request.urlopen(url, timeout=10) as resp:
                      body = resp.read().decode()
                      # Response is a redirect URL containing activationKey=...
                      if 'activationKey=' in body:
                          activation_key = body.split('activationKey=')[1].split('&')[0]
                          break
              except Exception as e:
                  print(f'Attempt {attempt+1}: {e}')
                  time.sleep(15)

          if not activation_key:
              raise RuntimeError(f'Failed to get activation key from agent {agent_ip}')

          print(f'Got activation key for agent {agent_key}')

          # Step 2: register the agent with DataSync
          ds = boto3.client('datasync', region_name=region)
          resp = ds.create_agent(
              ActivationKey=activation_key,
              AgentName=agent_name or agent_key,
              Tags=tags,
          )
          agent_arn = resp['AgentArn']
          print(f'Registered agent: {agent_arn}')

          # Step 3: write ARN to SSM so Terraform can read it
          ssm = boto3.client('ssm', region_name=region)
          ssm.put_parameter(Name=ssm_param, Value=agent_arn, Type='String', Overwrite=True)

          return {'agent_arn': agent_arn, 'activation_key': activation_key}
    PYTHON
    filename = "index.py"
  }
}

resource "aws_lambda_function" "activation" {
  for_each = length(var.agents) > 0 ? var.agents : {}

  function_name = "${local.name}-datasync-activate-${each.key}"
  role          = aws_iam_role.activation_lambda[0].arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = var.activation_lambda_timeout
  memory_size   = 256

  filename         = data.archive_file.activation_lambda[0].output_path
  source_code_hash = data.archive_file.activation_lambda[0].output_base64sha256

  vpc_config {
    subnet_ids         = var.activation_lambda_subnet_ids
    security_group_ids = var.activation_lambda_security_group_ids
  }

  environment {
    variables = {
      AGENT_KEY = each.key
    }
  }

  tags = local.tags

  depends_on = [aws_instance.agent]
}

# ---------------------------------------------------------------------------
# Invoke the activation Lambda (runs once per agent)
# Uses null_resource + local-exec calling the Lambda synchronously
# ---------------------------------------------------------------------------
resource "aws_lambda_invocation" "activation" {
  for_each = var.agents

  function_name = aws_lambda_function.activation[each.key].function_name

  input = jsonencode({
    agent_ip              = aws_instance.agent[each.key].private_ip
    agent_name            = coalesce(each.value.name, each.key)
    agent_key             = each.key
    region                = coalesce(each.value.activation_region, data.aws_region.current.name)
    ssm_param             = "/datasync/${local.name}/agents/${each.key}/arn"
    private_link_endpoint = each.value.private_link_endpoint
    tags = [
      for k, v in merge(local.tags, { Name = coalesce(each.value.name, each.key) }) : { Key = k, Value = v }
    ]
  })

  # Re-run activation only if the EC2 instance is replaced
  triggers = {
    instance_id = aws_instance.agent[each.key].id
  }

  depends_on = [aws_ssm_parameter.agent_ip]
}

# ---------------------------------------------------------------------------
# Read the agent ARN written by the Lambda from SSM
# ---------------------------------------------------------------------------
data "aws_ssm_parameter" "agent_arn" {
  for_each = var.agents

  name = "/datasync/${local.name}/agents/${each.key}/arn"

  depends_on = [aws_lambda_invocation.activation]
}

# ---------------------------------------------------------------------------
# Import-register the activated agent as a Terraform-managed resource
# (Terraform reads the ARN; AWS already has the agent registered)
# ---------------------------------------------------------------------------
resource "aws_datasync_agent" "this" {
  for_each = var.agents

  # activation_key is intentionally blank — agent was already activated by Lambda.
  # The agent_arn import pattern: provide the activation_key from the Lambda output.
  activation_key = jsondecode(aws_lambda_invocation.activation[each.key].result)["activation_key"]
  name           = coalesce(each.value.name, each.key)

  private_link_endpoint      = each.value.private_link_endpoint
  security_group_arns        = [for sg in each.value.security_group_ids : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/${sg}"]
  subnet_arns                = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${each.value.subnet_id}"]
  vpc_endpoint_id            = null  # set if using VPC endpoint for DataSync

  tags = merge(local.tags, each.value.additional_tags)

  lifecycle {
    # Agent activation is one-time; prevent Terraform from re-running it
    ignore_changes = [activation_key]
  }
}
