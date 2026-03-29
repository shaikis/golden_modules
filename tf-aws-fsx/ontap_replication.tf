# =============================================================================
# FSx ONTAP - SnapMirror Cross-Region Replication
#
# Uses the NetApp ONTAP Terraform provider to configure ONTAP-native
# replication between two FSx ONTAP file systems (source and destination).
#
# PREREQUISITE:
#   Terraform must run from a host with HTTPS access to both ONTAP management
#   endpoints (typically from within the VPC via EC2, CodeBuild, or a VPN).
#
# REPLICATION MODES:
#   async      (default) - transfers snapshots on a schedule (hourly/daily)
#                          RPO = schedule interval, low network cost
#   sync       - synchronous replication within a region (near-zero RPO)
#                avoid across high-latency cross-region links
#   strictSync - fully synchronous; I/O is blocked if replication breaks
#
# FAILOVER PROCEDURE (async mode):
#   1. Break the SnapMirror relationship on the destination cluster:
#        snapmirror break -destination-path <dst-svm>:<dst-vol>
#   2. Promote the destination SVM/volume to read-write
#   3. Update DNS or Route 53 to point to the DR endpoint
#   4. (Recovery) Resync from destination back to source after primary is restored
# =============================================================================

# ---------------------------------------------------------------------------
# ONTAP provider instances - one per cluster endpoint
# ---------------------------------------------------------------------------
provider "netapp-ontap" {
  alias = "source"

  connection_profiles = [{
    name           = "source"
    hostname       = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.source_management_ip : "unused"
    username       = "fsxadmin"
    password       = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.source_admin_password : "unused"
    port           = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.source_https_port : 443
    validate_certs = false # FSx ONTAP uses self-signed certs on the management endpoint
  }]
}

provider "netapp-ontap" {
  alias = "destination"

  connection_profiles = [{
    name           = "destination"
    hostname       = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.destination_management_ip : "unused"
    username       = "fsxadmin"
    password       = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.destination_admin_password : "unused"
    port           = var.enable_ontap_snapmirror ? local.resolved_ontap_snapmirror.destination_https_port : 443
    validate_certs = false
  }]
}

# ---------------------------------------------------------------------------
# Cluster peering - establishes the inter-cluster trust relationship
# required for SnapMirror replication traffic between regions
# ---------------------------------------------------------------------------
resource "netapp-ontap_cluster_peers_resource" "this" {
  count    = var.enable_ontap_snapmirror ? 1 : 0
  provider = netapp-ontap.source

  cx_profile_name      = "source"
  peer_cx_profile_name = "destination"
  passphrase           = "${local.name}-cluster-peer-${random_id.peer_passphrase[0].hex}"
  generate_passphrase  = false
  peer_applications    = ["snapmirror"]

  source_details = {
    ip_addresses = [
      local.resolved_ontap_snapmirror.source_management_ip,
    ]
  }

  remote = {
    ip_addresses = [
      local.resolved_ontap_snapmirror.destination_management_ip,
    ]
  }
}

resource "random_id" "peer_passphrase" {
  count       = var.enable_ontap_snapmirror ? 1 : 0
  byte_length = 16
}

# ---------------------------------------------------------------------------
# SVM peering - required before SnapMirror relationships can be created
# ---------------------------------------------------------------------------
resource "netapp-ontap_svm_peers_resource" "volume_sm" {
  for_each = var.enable_ontap_snapmirror ? (
    var.ontap_snapmirror != null ? var.ontap_snapmirror.volume_relationships : {}
  ) : {}

  provider        = netapp-ontap.source
  cx_profile_name = "source"
  applications    = ["snapmirror"]

  svm = {
    name = aws_fsx_ontap_storage_virtual_machine.this[each.value.source_svm_key].name
  }

  peer = {
    cluster = {
      name = "destination"
    }
    svm = {
      name = each.value.destination_svm_name
    }
    peer_cx_profile_name = "destination"
  }

  depends_on = [netapp-ontap_cluster_peers_resource.this]
}

resource "netapp-ontap_svm_peers_resource" "svm_dr" {
  for_each = var.enable_ontap_snapmirror ? (
    var.ontap_snapmirror != null ? var.ontap_snapmirror.svm_dr_relationships : {}
  ) : {}

  provider        = netapp-ontap.source
  cx_profile_name = "source"
  applications    = ["snapmirror"]

  svm = {
    name = aws_fsx_ontap_storage_virtual_machine.this[each.value.source_svm_key].name
  }

  peer = {
    cluster = {
      name = "destination"
    }
    svm = {
      name = each.value.destination_svm_name
    }
    peer_cx_profile_name = "destination"
  }

  depends_on = [netapp-ontap_cluster_peers_resource.this]
}

# ---------------------------------------------------------------------------
# SnapMirror Policy (async)
# ---------------------------------------------------------------------------
resource "netapp-ontap_snapmirror_policy_resource" "volume_async" {
  for_each = (
    var.enable_ontap_snapmirror &&
    var.ontap_snapmirror != null &&
    var.ontap_snapmirror.replication_mode == "async"
    ) ? {
    for k, v in var.ontap_snapmirror.volume_relationships : k => v
  } : {}

  provider               = netapp-ontap.destination
  cx_profile_name        = "destination"
  name                   = "${local.name}-sm-${each.key}"
  svm_name               = each.value.destination_svm_name
  type                   = "async"
  transfer_schedule_name = var.ontap_snapmirror.schedule
  comment                = "Managed by tf-aws-fsx module for ${local.name}"

  retention = [{
    label                  = "hourly"
    count                  = 24
    creation_schedule_name = var.ontap_snapmirror.schedule
  }]
}

# ---------------------------------------------------------------------------
# SnapMirror Policy (sync / strictSync)
# ---------------------------------------------------------------------------
resource "netapp-ontap_snapmirror_policy_resource" "volume_sync" {
  for_each = (
    var.enable_ontap_snapmirror &&
    var.ontap_snapmirror != null &&
    var.ontap_snapmirror.replication_mode != "async"
    ) ? {
    for k, v in var.ontap_snapmirror.volume_relationships : k => v
  } : {}

  provider        = netapp-ontap.destination
  cx_profile_name = "destination"
  name            = "${local.name}-sm-${each.key}"
  svm_name        = each.value.destination_svm_name
  type            = "sync"
  sync_type = var.ontap_snapmirror.replication_mode == "strictSync" ? "strict_sync" : (
    var.ontap_snapmirror.replication_mode == "sync" ? "sync" : null
  )
  comment = "Managed by tf-aws-fsx module for ${local.name}"
}

# ---------------------------------------------------------------------------
# SnapMirror relationships - volume level
# Destination volumes are created by the SnapMirror resource when enabled.
# ---------------------------------------------------------------------------
resource "netapp-ontap_snapmirror_resource" "volume" {
  for_each = var.enable_ontap_snapmirror && var.ontap_snapmirror != null ? {
    for k, v in var.ontap_snapmirror.volume_relationships : k => v
  } : {}

  provider        = netapp-ontap.destination
  cx_profile_name = "destination"

  create_destination = {
    enabled = true
  }

  source_endpoint = {
    path = "${aws_fsx_ontap_storage_virtual_machine.this[each.value.source_svm_key].name}:${var.ontap.svms[each.value.source_svm_key].volumes[each.value.source_volume_key].name}"
    cluster = {
      name = "source"
    }
  }

  destination_endpoint = {
    path = "${each.value.destination_svm_name}:${each.value.destination_volume_name}"
    cluster = {
      name = "destination"
    }
  }

  policy = {
    name = var.ontap_snapmirror.replication_mode == "async" ? (
      netapp-ontap_snapmirror_policy_resource.volume_async[each.key].name
      ) : (
      netapp-ontap_snapmirror_policy_resource.volume_sync[each.key].name
    )
  }

  initialize = true

  depends_on = [netapp-ontap_svm_peers_resource.volume_sm]
}

# ---------------------------------------------------------------------------
# SVM DR relationships (replicates entire SVM - config + data)
# ---------------------------------------------------------------------------
resource "netapp-ontap_snapmirror_resource" "svm_dr" {
  for_each = var.enable_ontap_snapmirror && var.ontap_snapmirror != null ? {
    for k, v in var.ontap_snapmirror.svm_dr_relationships : k => v
  } : {}

  provider        = netapp-ontap.destination
  cx_profile_name = "destination"

  source_endpoint = {
    path = aws_fsx_ontap_storage_virtual_machine.this[each.value.source_svm_key].name
    cluster = {
      name = "source"
    }
  }

  destination_endpoint = {
    path = each.value.destination_svm_name
    cluster = {
      name = "destination"
    }
  }

  policy = {
    name = "MirrorAllSnapshots"
  }
  initialize = true

  depends_on = [netapp-ontap_svm_peers_resource.svm_dr]
}
