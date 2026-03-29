variable "name" {
  description = "Base name for all resources."
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment label (dev / staging / prod)."
  type        = string
  default     = "prod"
}

# ── Region configuration ──────────────────────────────────────────────────────

variable "primary_region" {
  description = "AWS region for the primary FSx ONTAP cluster."
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "AWS region for the DR FSx ONTAP cluster."
  type        = string
  default     = "us-west-2"
}

# ── Primary region networking ─────────────────────────────────────────────────

variable "primary_subnet_ids" {
  description = "Two subnet IDs in the primary region (different AZs) for MULTI_AZ_1."
  type        = list(string)
}

variable "primary_security_group_ids" {
  description = "Security group IDs for the primary FSx ONTAP cluster."
  type        = list(string)
  default     = []
}

# ── DR region networking ──────────────────────────────────────────────────────

variable "dr_subnet_ids" {
  description = "Two subnet IDs in the DR region (different AZs) for MULTI_AZ_1."
  type        = list(string)
}

variable "dr_security_group_ids" {
  description = "Security group IDs for the DR FSx ONTAP cluster."
  type        = list(string)
  default     = []
}

# ── FSx ONTAP cluster sizing ──────────────────────────────────────────────────

variable "storage_capacity_gb" {
  description = "Storage capacity in GiB for each FSx ONTAP cluster (1024–196608)."
  type        = number
  default     = 1024
}

variable "throughput_capacity_mbs" {
  description = "Throughput capacity in MB/s per cluster (128 | 256 | 512 | 1024 | 2048)."
  type        = number
  default     = 512
}

variable "fsx_admin_password_secret_id" {
  description = "Secrets Manager secret ID or ARN containing the fsxadmin password."
  type        = string
}

variable "fsx_admin_password_secret_key" {
  description = "JSON key to read from the fsxadmin secret when the secret value is JSON."
  type        = string
  default     = "password"
}

variable "svm_admin_password_secret_id" {
  description = "Secrets Manager secret ID or ARN containing the SVM admin password."
  type        = string
}

variable "svm_admin_password_secret_key" {
  description = "JSON key to read from the SVM admin secret when the secret value is JSON."
  type        = string
  default     = "password"
}

# ── Volume sizing ─────────────────────────────────────────────────────────────

variable "data_volume_size_gb" {
  description = "Size of the 'data' volume in GiB."
  type        = number
  default     = 200
}

variable "logs_volume_size_gb" {
  description = "Size of the 'logs' volume in GiB."
  type        = number
  default     = 50
}

# ── SnapMirror ONTAP management endpoints ────────────────────────────────────
# These are available after the FSx ONTAP clusters are created.
# Navigate to: FSx Console → File system → Administration → Endpoints
# and copy the "Management" IP address.

variable "primary_ontap_management_ip" {
  description = <<-EOT
    Management IP of the primary FSx ONTAP cluster.
    Found in: FSx Console → File system → Administration → Endpoints → Management.
    Leave empty on first apply; set after clusters are created.
  EOT
  type        = string
  default     = ""
}

variable "dr_ontap_management_ip" {
  description = <<-EOT
    Management IP of the DR FSx ONTAP cluster.
    Found in: FSx Console → File system → Administration → Endpoints → Management.
    Leave empty on first apply; set after clusters are created.
  EOT
  type        = string
  default     = ""
}

# ── Route 53 DNS failover ─────────────────────────────────────────────────────

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS failover records."
  type        = string
}

variable "domain" {
  description = "Domain name used to construct NFS endpoint CNAME (e.g. example.com)."
  type        = string
}
