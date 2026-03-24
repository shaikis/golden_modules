resource "aws_cloudwatch_event_connection" "this" {
  for_each = var.create_api_connections ? var.api_connections : {}

  name               = each.key
  description        = each.value.description
  authorization_type = each.value.authorization_type

  auth_parameters {
    dynamic "api_key" {
      for_each = each.value.authorization_type == "API_KEY" ? [1] : []
      content {
        key   = each.value.api_key_name
        value = each.value.api_key_value
      }
    }

    dynamic "basic" {
      for_each = each.value.authorization_type == "BASIC" ? [1] : []
      content {
        username = each.value.basic_username
        password = each.value.basic_password
      }
    }

    dynamic "oauth" {
      for_each = each.value.authorization_type == "OAUTH_CLIENT_CREDENTIALS" ? [1] : []
      content {
        authorization_endpoint = each.value.oauth_authorization_endpoint
        http_method            = each.value.oauth_http_method

        client_parameters {
          client_id     = each.value.oauth_client_id
          client_secret = each.value.oauth_client_secret
        }

        dynamic "oauth_http_parameters" {
          for_each = each.value.oauth_scope != null ? [1] : []
          content {
            body {
              key             = "scope"
              value           = each.value.oauth_scope
              is_value_secret = false
            }
          }
        }
      }
    }
  }
}
