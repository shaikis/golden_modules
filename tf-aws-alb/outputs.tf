output "security_group_id"   { value = try(aws_security_group.this[0].id, null) }
output "lb_id"               { value = aws_lb.this.id }
output "lb_arn"              { value = aws_lb.this.arn }
output "lb_dns_name"         { value = aws_lb.this.dns_name }
output "lb_zone_id"          { value = aws_lb.this.zone_id }
output "lb_arn_suffix"       { value = aws_lb.this.arn_suffix }
output "target_group_arns"   { value = { for k, v in aws_lb_target_group.this : k => v.arn } }
output "target_group_names"  { value = { for k, v in aws_lb_target_group.this : k => v.name } }
output "target_group_arn_suffixes" { value = { for k, v in aws_lb_target_group.this : k => v.arn_suffix } }
output "listener_arns"       { value = { for k, v in aws_lb_listener.this : k => v.arn } }
output "listener_rule_arns"  { value = { for k, v in aws_lb_listener_rule.this : k => v.arn } }
