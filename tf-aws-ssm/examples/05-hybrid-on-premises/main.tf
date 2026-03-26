# =============================================================================
# Example: Hybrid Cloud — On-Premises Server Management via SSM
# =============================================================================
# Manage on-premises factory servers using AWS SSM — no VPN required.
# The SSM Agent runs on each server and communicates outbound HTTPS to SSM endpoints.
#
# Use case: Manufacturing company with 50 Windows servers in OT network
#   - Patch Manager:          keep factory servers patched (WSUS replacement)
#   - Session Manager:        remote access without VPN or RDP exposure
#   - State Manager:          enforce configurations, disable RDP, install agents
#   - Resource Data Sync:     export inventory to S3 for Athena compliance queries
# =============================================================================

module "ssm_hybrid" {
  source      = "../../"
  name        = "manufacturing-corp"
  environment = "prod"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  # ---------------------------------------------------------------------------
  # HYBRID ACTIVATION — Register 50 on-premises Windows servers
  # ---------------------------------------------------------------------------
  # This creates an Activation ID + Activation Code pair.
  # Run the agent registration command on each factory server using these values.
  # Registered servers appear in SSM Fleet Manager as "mi-xxxxxxxxxxxxxxxxx" IDs.
  # ---------------------------------------------------------------------------
  create_activation             = true
  activation_description        = "Factory floor Windows servers — Building A, Racks 1-5"
  activation_registration_limit = 60  # 50 servers + 10 buffer for replacements
  activation_expiration_date    = "2026-12-31T23:59:59Z"
  activation_iam_role_name      = null # Auto-creates role with AmazonSSMManagedInstanceCore

  # ---------------------------------------------------------------------------
  # PATCH MANAGER — Replace WSUS with SSM Patch Manager
  # ---------------------------------------------------------------------------
  # OT (Operational Technology) environments require extra conservatism:
  #   - Longer approval delays (14 days vs 7 days in IT)
  #   - Only Critical severity (not Important) to minimize reboot risk
  #   - Explicit rejected patches list for patches known to break SCADA/PLC drivers
  # ---------------------------------------------------------------------------
  create_patch_baselines = true

  patch_baselines = {
    "factory-windows" = {
      operating_system = "WINDOWS"
      description      = "Factory floor Windows — Critical security patches, 14-day approval (OT stability)"
      default_baseline = true

      approval_rules = [
        {
          approve_after_days = 14  # Longer delay for OT systems — stability is critical
          compliance_level   = "CRITICAL"
          patch_filters = [
            { key = "CLASSIFICATION", values = ["CriticalUpdates", "SecurityUpdates"] },
            { key = "MSRC_SEVERITY", values = ["Critical"] } # Only Critical in OT (not Important)
          ]
        }
      ]

      # Patches known to interfere with factory software — explicitly blocked
      rejected_patches = [
        "KB5004945", # Known to interfere with factory SCADA software (WinCC)
        "KB4592438"  # Caused issues with PLC communication drivers (S7 protocol)
      ]
    }
  }

  patch_groups = {
    "factory-windows-ot" = "factory-windows"
  }

  # ---------------------------------------------------------------------------
  # MAINTENANCE WINDOWS — Saturday night during factory production stop
  # ---------------------------------------------------------------------------
  maintenance_windows = {
    "factory-weekend-patching" = {
      schedule          = "cron(0 22 ? * SAT *)" # Saturday 22:00 UTC
      duration          = 4                       # 4-hour window (22:00–02:00 UTC)
      cutoff            = 1                       # Stop new tasks 1 hour before end
      description       = "Factory OT server patching — Saturday 22:00 UTC (weekend production stop)"
      schedule_timezone = "UTC"

      targets = [
        { key = "tag:Patch Group", values = ["factory-windows-ot"] }
      ]

      tasks = {
        "patch-factory-servers" = {
          task_type       = "RUN_COMMAND"
          document_name   = "AWS-RunPatchBaseline"
          priority        = 1
          max_concurrency = "10"   # Absolute: only 10 servers simultaneously (OT caution)
          max_errors      = "3"    # Stop entirely after 3 failures (OT reliability threshold)
          parameters = {
            Operation    = ["Install"]
            RebootOption = ["RebootIfNeeded"]
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # SESSION MANAGER — Replace VPN + RDP with secure browser/CLI access
  # ---------------------------------------------------------------------------
  enable_session_manager               = true
  session_manager_s3_bucket            = "manufacturing-corp-ssm-logs"
  session_manager_cloudwatch_log_group = "/aws/ssm/factory-sessions"
  session_manager_log_retention_days   = 365 # 1 year for OT audit compliance (IEC 62443)

  # ---------------------------------------------------------------------------
  # STATE MANAGER — Enforce security configurations on all factory servers
  # ---------------------------------------------------------------------------
  associations = {

    # Enforce CloudWatch Agent on all factory servers for metrics + log collection
    "enforce-cw-agent" = {
      document_name       = "AWS-ConfigureAWSPackage"
      schedule            = "rate(30 days)"
      compliance_severity = "HIGH"
      targets             = [{ key = "tag:SSMActivation", values = ["factory-floor"] }]
      parameters = {
        action = ["Install"]
        name   = ["AmazonCloudWatchAgent"]
      }
    }

    # Daily software inventory — feeds Resource Data Sync for compliance reports
    "gather-software-inventory" = {
      document_name       = "AWS-GatherSoftwareInventory"
      schedule            = "rate(1 day)"
      compliance_severity = "MEDIUM"
      targets             = [{ key = "InstanceIds", values = ["*"] }]
      parameters          = {}
    }

    # Enforce security baseline: disable RDP (port 3389) on factory servers
    # OT servers should only be accessed via Session Manager, never via RDP
    "enforce-windows-security-settings" = {
      document_name       = "AWS-RunPowerShellScript"
      schedule            = "rate(7 days)"
      compliance_severity = "HIGH"
      targets             = [{ key = "tag:SSMActivation", values = ["factory-floor"] }]
      parameters = {
        commands = [
          # Disable RDP at registry level
          "Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server' -Name fDenyTSConnections -Value 1",
          # Disable RDP via Windows Firewall
          "netsh advfirewall firewall set rule group='Remote Desktop' new enable=No",
          # Enforce Windows Defender real-time protection
          "Set-MpPreference -DisableRealtimeMonitoring $false",
          # Log result for SSM compliance
          "Write-Host 'Security baseline enforced: RDP disabled, Defender enabled'"
        ]
      }
    }

    # Verify SCADA software version before patching (custom compliance check)
    "verify-scada-compatibility" = {
      document_name       = "AWS-RunPowerShellScript"
      schedule            = "rate(1 day)"
      compliance_severity = "HIGH"
      targets             = [{ key = "tag:SSMActivation", values = ["factory-floor"] }]
      parameters = {
        commands = [
          # Check if SCADA software is installed and log version
          "$scadaPath = 'C:\\Program Files\\Siemens\\WinCC'",
          "if (Test-Path $scadaPath) {",
          "  $version = (Get-ItemProperty '$scadaPath\\WinCC.exe').VersionInfo.FileVersion",
          "  Write-Host \"SCADA version: $version\"",
          "} else {",
          "  Write-Host 'WARNING: SCADA software not found at expected path'",
          "}"
        ]
      }
    }
  }

  # ---------------------------------------------------------------------------
  # RESOURCE DATA SYNC — Export SSM inventory to S3 for compliance reporting
  # ---------------------------------------------------------------------------
  # Once data lands in S3, create an Athena table over it to run SQL queries
  # for compliance audits (IEC 62443, NERC CIP, ISO 27001).
  # ---------------------------------------------------------------------------
  resource_data_syncs = {
    "factory-inventory-sync" = {
      s3_bucket_name = "manufacturing-corp-compliance-inventory"
      s3_region      = "us-east-1"
      s3_prefix      = "ssm-inventory/factory/"
      sync_format    = "JsonSerDe"
    }
  }

  # ---------------------------------------------------------------------------
  # PARAMETER STORE — Factory-specific configuration
  # ---------------------------------------------------------------------------
  parameters = {
    "/prod/manufacturing/factory/scada_version" = {
      value       = "WinCC_v17.0.1"
      type        = "String"
      description = "SCADA software version — used to validate patch compatibility before approving"
    }
    "/prod/manufacturing/factory/plc_ip_range" = {
      value       = "192.168.10.0/24,192.168.11.0/24"
      type        = "StringList"
      description = "PLC network CIDR ranges — excluded from patch reboot impact assessment"
    }
    "/prod/manufacturing/factory/maintenance_contact" = {
      value       = "ot-team@manufacturing-corp.com"
      type        = "String"
      description = "OT team contact for patch window notifications and approval"
    }
    "/prod/manufacturing/factory/patch_approval_required" = {
      value           = "true"
      type            = "String"
      description     = "Set to false during emergency patching cycle"
      allowed_pattern = "^(true|false)$"
    }
    "/prod/manufacturing/aws/account_id" = {
      value       = "123456789012"
      type        = "String"
      description = "AWS account ID used for SSM hybrid activation"
    }
  }

  tags = {
    CostCenter = "operations"
    Compliance = "IEC-62443"
    Facility   = "plant-a"
  }
}

# ---------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------
output "activation_id" {
  description = "Hybrid activation ID — pass to amazon-ssm-agent -register command on each factory server"
  value       = module.ssm_hybrid.activation_id
}

output "activation_code" {
  description = "Hybrid activation code — used with activation_id to register servers. Treat as a secret."
  value       = module.ssm_hybrid.activation_code
  sensitive   = true
}

output "patch_baseline_ids" {
  description = "Map of baseline name -> baseline ID"
  value       = module.ssm_hybrid.patch_baseline_ids
}

output "association_ids" {
  description = "Map of association name -> association ID"
  value       = module.ssm_hybrid.association_ids
}

output "maintenance_window_ids" {
  description = "Map of maintenance window name -> window ID"
  value       = module.ssm_hybrid.maintenance_window_ids
}
