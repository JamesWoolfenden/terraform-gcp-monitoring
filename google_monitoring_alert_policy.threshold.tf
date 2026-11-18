resource "google_monitoring_alert_policy" "threshold" {
  for_each = local.threshold_policies

  display_name          = each.value.display_name
  combiner              = each.value.combiner
  enabled               = each.value.enabled
  severity              = each.value.severity
  notification_channels = local.alert_policy_channels[each.key]
  user_labels           = var.labels

  documentation {
    content   = each.value.documentation.content
    mime_type = each.value.documentation.mime_type
    subject   = each.value.documentation.subject
  }

  alert_strategy {
    auto_close = each.value.auto_close
  }

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      condition_threshold {
        filter          = conditions.value.condition_threshold.filter
        comparison      = conditions.value.condition_threshold.comparison
        threshold_value = conditions.value.condition_threshold.threshold_value
        duration        = conditions.value.condition_threshold.duration

        dynamic "aggregations" {
          for_each = conditions.value.condition_threshold.aggregations
          content {
            alignment_period     = aggregations.value.alignment_period
            per_series_aligner   = aggregations.value.per_series_aligner
            cross_series_reducer = aggregations.value.cross_series_reducer
            group_by_fields      = aggregations.value.group_by_fields
          }
        }
      }
    }
  }
}
