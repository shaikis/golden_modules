variable "zone_name" {
  description = "The DNS domain name for the public hosted zone (e.g. 'example.com')."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for resource naming (e.g. 'dev', 'prod')."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment label added to all resource tags."
  type        = string
  default     = "dev"
}

variable "root_ip" {
  description = "IPv4 address for the zone apex A record."
  type        = string
  default     = "203.0.113.10"
}

variable "root_ipv6" {
  description = "IPv6 address for the zone apex AAAA record."
  type        = string
  default     = "2001:db8::1"
}

variable "email_mx_records" {
  description = "List of MX record values (e.g. '10 mail.example.com')."
  type        = list(string)
  default     = ["10 mail.example.com.", "20 mail2.example.com."]
}

variable "spf_record" {
  description = "SPF TXT record value (e.g. 'v=spf1 include:_spf.google.com ~all')."
  type        = string
  default     = "v=spf1 include:_spf.google.com ~all"
}

variable "dmarc_record" {
  description = "DMARC TXT record value."
  type        = string
  default     = "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; pct=100"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
