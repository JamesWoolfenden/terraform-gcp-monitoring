resource "google_monitoring_dashboard" "main" {
  count = var.dashboard_json == null ? 0 : 1

  dashboard_json = var.dashboard_json
}
