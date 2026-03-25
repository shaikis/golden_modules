output "guardrail_ids" { value = { for k, v in aws_bedrock_guardrail.this : k => v.guardrail_id } }
output "guardrail_arns" { value = { for k, v in aws_bedrock_guardrail.this : k => v.guardrail_arn } }
output "knowledge_base_ids" { value = { for k, v in aws_bedrockagent_knowledge_base.this : k => v.id } }
output "knowledge_base_arns" { value = { for k, v in aws_bedrockagent_knowledge_base.this : k => v.arn } }
output "agent_ids" { value = { for k, v in aws_bedrockagent_agent.this : k => v.agent_id } }
output "agent_arns" { value = { for k, v in aws_bedrockagent_agent.this : k => v.agent_arn } }
