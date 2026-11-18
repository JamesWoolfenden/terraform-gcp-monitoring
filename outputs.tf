# holden:ignore:HLD_TF_080 — only the resource ID is output; IDs are not derived from sensitive_labels and are not marked sensitive by the provider
output "notification_channel_ids" {
  value       = { for k, v in google_monitoring_notification_channel.main : k => v.id }
  description = "Map of notification channel key to channel ID"
}

# holden:ignore:HLD_TF_080 — only the resource ID is output; IDs are not derived from sensitive_labels and are not marked sensitive by the provider
output "alert_policy_ids" {
  value       = merge({ for k, v in google_monitoring_alert_policy.threshold : k => v.id }, { for k, v in google_monitoring_alert_policy.log_match : k => v.id })
  description = "Map of alert policy key to alert policy ID"
}

# holden:ignore:HLD_TF_080 — only the resource ID is output; IDs are not derived from sensitive_labels and are not marked sensitive by the provider
output "uptime_alert_policy_ids" {
  value       = { for k, v in google_monitoring_alert_policy.uptime : k => v.id }
  description = "Map of uptime check key to the ID of the alert policy that fires when that check fails"
}

output "uptime_check_ids" {
  value       = { for k, v in google_monitoring_uptime_check_config.main : k => v.uptime_check_id }
  description = "Map of uptime check key to uptime check ID"
}

output "dashboard_id" {
  value       = one(google_monitoring_dashboard.main[*].id)
  description = "ID of the dashboard, or null when var.dashboard_json is not set"
}
