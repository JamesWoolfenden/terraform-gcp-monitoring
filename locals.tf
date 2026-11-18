locals {
  # Cloud Monitoring notification service agent — the identity that publishes
  # alert notifications to Pub/Sub notification channels.
  monitoring_notification_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"

  pubsub_channels = { for k, v in var.notification_channels : k => v if v.type == "pubsub" }

  # Alert policies and uptime checks reference channels either by key in
  # var.notification_channels or by full channel ID.
  channel_ids = { for k, v in google_monitoring_notification_channel.main : k => v.id }

  alert_policy_channels = { for k, v in var.alert_policies : k => [for c in v.notification_channels : lookup(local.channel_ids, c, c)] }
  uptime_check_channels = { for k, v in var.uptime_checks : k => [for c in v.notification_channels : lookup(local.channel_ids, c, c)] }

  # Channel references that are neither a known key nor a full channel ID (usually a mistyped key).
  channel_refs            = distinct(concat(flatten(values(var.alert_policies)[*].notification_channels), flatten(values(var.uptime_checks)[*].notification_channels)))
  unresolved_channel_refs = [for c in local.channel_refs : c if !contains(keys(var.notification_channels), c) && !can(regex("^projects/[^/]+/notificationChannels/[^/]+$", c))]

  # Uptime checks that page someone when they fail.
  alerting_uptime_checks = { for k, v in var.uptime_checks : k => v if length(v.notification_channels) > 0 }

  # GCP only allows a log-match condition as the single condition of a policy, so
  # log-match and metric-threshold policies are managed by separate resources.
  log_policies       = { for k, v in var.alert_policies : k => v if v.conditions[0].condition_matched_log != null }
  threshold_policies = { for k, v in var.alert_policies : k => v if v.conditions[0].condition_matched_log == null }
}
