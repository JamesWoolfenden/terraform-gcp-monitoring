resource "google_monitoring_alert_policy" "log_match" {
  for_each = local.log_policies

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

    # Required for log-match policies; bounds how often a noisy log can page.
    notification_rate_limit {
      period = each.value.notification_rate_limit_period
    }
  }

  conditions {
    display_name = each.value.conditions[0].display_name

    condition_matched_log {
      filter           = each.value.conditions[0].condition_matched_log.filter
      label_extractors = each.value.conditions[0].condition_matched_log.label_extractors
    }
  }
}
