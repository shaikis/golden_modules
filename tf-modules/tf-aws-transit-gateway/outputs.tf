output "tgw_id" { value = aws_ec2_transit_gateway.this.id }
output "tgw_arn" { value = aws_ec2_transit_gateway.this.arn }
output "tgw_owner_id" { value = aws_ec2_transit_gateway.this.owner_id }
output "tgw_default_route_table_id" { value = aws_ec2_transit_gateway.this.association_default_route_table_id }
output "vpc_attachment_ids" { value = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id } }
output "route_table_ids" { value = { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id } }
output "ram_share_arn" { value = length(aws_ram_resource_share.this) > 0 ? aws_ram_resource_share.this[0].arn : null }
