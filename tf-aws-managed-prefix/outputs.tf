output "id" {
  value = aws_ec2_managed_prefix_list.this.id
}

output "entries" {
  value = local.sorted_entries
}