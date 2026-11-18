# Lets the Cloud Monitoring notification service agent publish to Pub/Sub notification channel topics.
resource "google_pubsub_topic_iam_member" "notification_publisher" {
  for_each = local.pubsub_channels

  topic  = each.value.labels["topic"]
  role   = "roles/pubsub.publisher"
  member = local.monitoring_notification_agent

  # The notification service agent only exists once the project's first Pub/Sub
  # channel has been created, so the grant must wait for the channels.
  depends_on = [google_monitoring_notification_channel.main]
}
