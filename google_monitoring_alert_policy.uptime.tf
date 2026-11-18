# Pages the uptime check's notification channels when the check fails from any checker region.
resource "google_monitoring_alert_policy" "uptime" {
  for_each = local.alerting_uptime_checks

  display_name          = "${each.value.display_name} failing"
  combiner              = "OR"
  severity              = "ERROR"
  notification_channels = local.uptime_check_channels[each.key]
  user_labels           = var.labels

  documentation {
    content   = "Uptime check \"${each.value.display_name}\" against https://${each.value.host}${each.value.path} is failing. Check the host is serving and its certificate is valid."
    mime_type = "text/markdown"
  }

  alert_strategy {
    auto_close = "1800s"
  }

  conditions {
    display_name = "${each.value.display_name} check failed"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.main[each.key].uptime_check_id}\" AND resource.type=\"uptime_url\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "60s"

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }

      trigger {
        count = 1
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.unresolved_channel_refs) == 0
      error_message = "notification_channels entries must be keys of var.notification_channels or full projects/P/notificationChannels/ID values; unresolved: ${join(", ", local.unresolved_channel_refs)}"
    }
  }
}
