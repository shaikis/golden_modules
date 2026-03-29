locals {
  name = var.name_prefix != "" ? "${var.name_prefix}-${var.name}" : var.name

  tags = merge(
    {
      Name        = local.name
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Module      = "tf-aws-fsx"
    },
    var.tags
  )

  ontap_fsx_admin_password = var.ontap == null ? null : coalesce(
    var.ontap.fsx_admin_password,
    try(jsondecode(data.aws_secretsmanager_secret_version.ontap_fsx_admin[0].secret_string)[var.ontap.fsx_admin_password_secret_key], null),
    try(data.aws_secretsmanager_secret_version.ontap_fsx_admin[0].secret_string, null),
  )

  resolved_windows = var.windows == null ? null : merge(var.windows, {
    self_managed_ad = var.windows.self_managed_ad == null ? null : merge(var.windows.self_managed_ad, {
      password = coalesce(
        var.windows.self_managed_ad.password,
        try(jsondecode(data.aws_secretsmanager_secret_version.windows_self_managed_ad_password[0].secret_string)[var.windows.self_managed_ad.password_secret_key], null),
        try(data.aws_secretsmanager_secret_version.windows_self_managed_ad_password[0].secret_string, null),
      )
    })
  })

  resolved_ontap = var.ontap == null ? null : merge(var.ontap, {
    fsx_admin_password = local.ontap_fsx_admin_password
    svms = {
      for svm_key, svm in var.ontap.svms : svm_key => merge(svm, {
        svm_admin_password = coalesce(
          svm.svm_admin_password,
          try(jsondecode(data.aws_secretsmanager_secret_version.ontap_svm_admin_password[svm_key].secret_string)[svm.svm_admin_password_secret_key], null),
          try(data.aws_secretsmanager_secret_version.ontap_svm_admin_password[svm_key].secret_string, null),
        )
        active_directory = svm.active_directory == null ? null : merge(svm.active_directory, {
          password = coalesce(
            svm.active_directory.password,
            try(jsondecode(data.aws_secretsmanager_secret_version.ontap_active_directory_password[svm_key].secret_string)[svm.active_directory.password_secret_key], null),
            try(data.aws_secretsmanager_secret_version.ontap_active_directory_password[svm_key].secret_string, null),
          )
        })
      })
    }
  })

  resolved_ontap_snapmirror = var.ontap_snapmirror == null ? null : merge(var.ontap_snapmirror, {
    source_admin_password = coalesce(
      var.ontap_snapmirror.source_admin_password,
      try(jsondecode(data.aws_secretsmanager_secret_version.snapmirror_source_admin_password[0].secret_string)[var.ontap_snapmirror.source_admin_password_secret_key], null),
      try(data.aws_secretsmanager_secret_version.snapmirror_source_admin_password[0].secret_string, null),
    )
    destination_admin_password = coalesce(
      var.ontap_snapmirror.destination_admin_password,
      try(jsondecode(data.aws_secretsmanager_secret_version.snapmirror_destination_admin_password[0].secret_string)[var.ontap_snapmirror.destination_admin_password_secret_key], null),
      try(data.aws_secretsmanager_secret_version.snapmirror_destination_admin_password[0].secret_string, null),
    )
  })
}
