###############################################################################
# EMR Security Configurations
###############################################################################

locals {
  security_config_jsons = {
    for k, v in var.security_configurations : k => jsonencode(merge(
      # Encryption Configuration
      {
        EncryptionConfiguration = merge(
          # At-rest encryption
          {
            EnableInTransitEncryption = v.enable_in_transit_encryption
            EnableAtRestEncryption    = v.enable_s3_encryption || v.enable_local_disk_encryption
          },
          v.enable_s3_encryption || v.enable_local_disk_encryption ? {
            AtRestEncryptionConfiguration = merge(
              v.enable_s3_encryption ? {
                S3EncryptionConfiguration = v.kms_key_arn != null ? {
                  EncryptionMode = "SSE-KMS"
                  AwsKmsKey      = v.kms_key_arn != null ? v.kms_key_arn : (var.kms_key_arn != null ? var.kms_key_arn : "")
                  } : {
                  EncryptionMode = "SSE-S3"
                }
              } : {},
              v.enable_local_disk_encryption ? {
                LocalDiskEncryptionConfiguration = v.kms_key_arn != null ? {
                  EncryptionKeyProviderType = "AwsKms"
                  AwsKmsKey                 = v.kms_key_arn != null ? v.kms_key_arn : (var.kms_key_arn != null ? var.kms_key_arn : "")
                  EnableEbsEncryption       = true
                  } : {
                  EncryptionKeyProviderType = "AwsKms"
                  EnableEbsEncryption       = false
                }
              } : {}
            )
          } : {},
          v.enable_in_transit_encryption && v.certificate_provider_class != null ? {
            InTransitEncryptionConfiguration = {
              TLSCertificateConfiguration = {
                CertificateProviderType = "Custom"
                S3Object                = v.certificate_provider_arg
              }
            }
          } : {}
        )
      },
      # Authentication / Kerberos
      v.enable_kerberos ? {
        AuthenticationConfiguration = {
          KerberosConfiguration = merge(
            {
              Provider = "ClusterDedicatedKdc"
              ClusterDedicatedKdcConfiguration = {
                TicketLifetimeInHours = 24
              }
            },
            v.kerberos_cross_realm_trust_realm != null ? {
              CrossRealmTrustConfiguration = {
                Realm       = v.kerberos_cross_realm_trust_realm
                Domain      = v.kerberos_cross_realm_trust_realm
                AdminServer = v.kerberos_cross_realm_trust_kdc
                KdcServer   = v.kerberos_cross_realm_trust_kdc
              }
            } : {}
          )
        }
      } : {},
      # Lake Formation
      v.enable_lake_formation ? {
        AuthorizationConfiguration = {
          LakeFormationConfiguration = {
            AuthorizationSessionType = "ENGINE_DEFAULT"
          }
        }
      } : {}
    ))
  }
}

resource "aws_emr_security_configuration" "this" {
  for_each = var.create_security_configurations ? var.security_configurations : {}

  name          = each.key
  configuration = local.security_config_jsons[each.key]
}
