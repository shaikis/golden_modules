zone_name   = "dev.example.com"
name_prefix = "dev"
environment = "dev"
root_ip     = "203.0.113.10"
root_ipv6   = "2001:db8::1"

email_mx_records = [
  "10 mail.dev.example.com.",
  "20 mail2.dev.example.com.",
]

spf_record   = "v=spf1 include:_spf.google.com ~all"
dmarc_record = "v=DMARC1; p=none; rua=mailto:dmarc@dev.example.com; pct=100"

tags = {
  CostCenter = "engineering"
  Team       = "platform"
}
