resource "google_monitoring_notification_channel" "main" {
  for_each = var.notification_channels

  display_name = each.value.display_name
  description  = each.value.description
  type         = each.value.type
  labels       = each.value.labels
  enabled      = each.value.enabled
  user_labels  = var.labels

  dynamic "sensitive_labels" {
    for_each = each.value.has_sensitive_labels ? [each.key] : []
    content {
      auth_token  = var.notification_channel_sensitive_labels[sensitive_labels.value].auth_token
      password    = var.notification_channel_sensitive_labels[sensitive_labels.value].password
      service_key = var.notification_channel_sensitive_labels[sensitive_labels.value].service_key
    }
  }
}
