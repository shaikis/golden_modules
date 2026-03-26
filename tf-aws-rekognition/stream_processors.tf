# ---------------------------------------------------------------------------
# Rekognition Stream Processors
# Controlled by: create_stream_processors = true
# ---------------------------------------------------------------------------

resource "aws_rekognition_stream_processor" "this" {
  for_each = var.create_stream_processors ? var.stream_processors : {}

  name     = "${local.name_prefix}${each.key}"
  role_arn = local.role_arn

  # ----- Input: Kinesis Video Stream -----
  input {
    kinesis_video_stream {
      arn = each.value.kinesis_video_stream_arn
    }
  }

  # ----- Output: Kinesis Data Stream -----
  output {
    kinesis_data_stream {
      arn = each.value.kinesis_data_stream_arn
    }
  }

  # ----- Analysis settings: face search (mutually exclusive with connected home) -----
  dynamic "settings" {
    for_each = each.value.face_search != null ? [each.value.face_search] : []
    content {
      face_search {
        collection_id        = settings.value.collection_id
        face_match_threshold = settings.value.face_match_threshold
      }
    }
  }

  dynamic "settings" {
    for_each = each.value.connected_home_labels != null ? [each.value] : []
    content {
      connected_home {
        labels           = settings.value.connected_home_labels
        min_confidence   = settings.value.connected_home_min_confidence
      }
    }
  }

  # ----- Optional SNS notification channel -----
  dynamic "notification_channel" {
    for_each = each.value.notification_sns_arn != null ? [each.value.notification_sns_arn] : []
    content {
      sns_topic_arn = notification_channel.value
    }
  }

  # ----- Data sharing preference -----
  data_sharing_preference {
    opt_in = each.value.data_sharing_preference_opt_in
  }

  # ----- Regions of interest (optional bounding boxes) -----
  dynamic "regions_of_interest" {
    for_each = each.value.regions_of_interest
    content {
      bounding_box {
        left   = regions_of_interest.value.left
        top    = regions_of_interest.value.top
        width  = regions_of_interest.value.width
        height = regions_of_interest.value.height
      }
    }
  }

  tags = merge(local.tags, each.value.tags)
}
