locals {
  # Cloud Monitoring notification service agent — the identity that publishes
  # alert notifications to Pub/Sub notification channels.
  monitoring_notification_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"

  pubsub_channels = { for k, v in var.notification_channels : k => v if v.type == "pubsub" }

  # Alert policies reference channels either by key in var.notification_channels or by full channel ID.
  alert_policy_channels = {
    for k, v in var.alert_policies : k => [
      for c in v.notification_channels : try(google_monitoring_notification_channel.main[c].id, c)
    ]
  }

  # GCP only allows a log-match condition as the single condition of a policy, so
  # log-match and metric-threshold policies are managed by separate resources.
  log_policies       = { for k, v in var.alert_policies : k => v if v.conditions[0].condition_matched_log != null }
  threshold_policies = { for k, v in var.alert_policies : k => v if v.conditions[0].condition_matched_log == null }
}
