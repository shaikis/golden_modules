output "queue_id" { value = aws_sqs_queue.this.id }
output "queue_arn" { value = aws_sqs_queue.this.arn }
output "queue_url" { value = aws_sqs_queue.this.url }
output "queue_name" { value = aws_sqs_queue.this.name }
output "dlq_id" { value = length(aws_sqs_queue.dlq) > 0 ? aws_sqs_queue.dlq[0].id : null }
output "dlq_arn" { value = length(aws_sqs_queue.dlq) > 0 ? aws_sqs_queue.dlq[0].arn : null }
output "dlq_url" { value = length(aws_sqs_queue.dlq) > 0 ? aws_sqs_queue.dlq[0].url : null }
