resource "google_monitoring_uptime_check_config" "main" {
  for_each = var.uptime_checks

  display_name       = each.value.display_name
  timeout            = each.value.timeout
  period             = each.value.period
  selected_regions   = each.value.selected_regions
  log_check_failures = true
  user_labels        = var.labels

  http_check {
    path           = each.value.path
    port           = each.value.port
    request_method = "GET"
    use_ssl        = true
    validate_ssl   = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = data.google_project.current.project_id
      host       = each.value.host
    }
  }

  dynamic "content_matchers" {
    for_each = each.value.content_matchers
    content {
      content = content_matchers.value.content
      matcher = content_matchers.value.matcher
    }
  }
}
