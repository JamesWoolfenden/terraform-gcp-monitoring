variable "notification_channels" {
  type = map(object({
    type                 = string
    display_name         = string
    description          = optional(string)
    labels               = map(string)
    enabled              = optional(bool, true)
    has_sensitive_labels = optional(bool, false)
  }))
  description = <<-EOT
  Map of notification channels to create. type is email (labels.email_address), pubsub (labels.topic, a full
  projects/P/topics/T ID), webhook_tokenauth (labels.url) or webhook_basicauth (labels.url, labels.username).
  Set has_sensitive_labels to read credentials for the channel from var.notification_channel_sensitive_labels.
  EOT
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.notification_channels) : contains(["email", "pubsub", "webhook_tokenauth", "webhook_basicauth"], v.type)])
    error_message = "var.notification_channels type must be one of email, pubsub, webhook_tokenauth or webhook_basicauth"
  }

  validation {
    condition     = alltrue([for v in values(var.notification_channels) : length(trimspace(v.display_name)) > 0])
    error_message = "var.notification_channels display_name must be non-empty"
  }

  validation {
    condition = alltrue([for v in values(var.notification_channels) :
      (v.type == "email" && can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", v.labels["email_address"]))) ||
      (v.type == "pubsub" && can(regex("^projects/[^/]+/topics/[^/]+$", v.labels["topic"]))) ||
      (startswith(v.type, "webhook_") && can(regex("^https://", v.labels["url"])))
    ])
    error_message = "var.notification_channels labels must match the type: email needs a valid email_address, pubsub a projects/P/topics/T topic, webhooks an https:// url"
  }

  validation {
    condition     = alltrue([for v in values(var.notification_channels) : length(setintersection(keys(v.labels), ["password", "auth_token", "service_key"])) == 0])
    error_message = "var.notification_channels labels must not contain password, auth_token or service_key; pass credentials through var.notification_channel_sensitive_labels with has_sensitive_labels = true so they are not stored as plain labels"
  }

  validation {
    condition     = alltrue([for v in values(var.notification_channels) : v.type != "webhook_basicauth" || (v.has_sensitive_labels && length(trimspace(lookup(v.labels, "username", ""))) > 0)])
    error_message = "var.notification_channels webhook_basicauth channels need labels.username and has_sensitive_labels = true (password in var.notification_channel_sensitive_labels)"
  }
}

variable "notification_channel_sensitive_labels" {
  type = map(object({
    auth_token  = optional(string)
    password    = optional(string)
    service_key = optional(string)
  }))
  description = "Credentials for notification channels with has_sensitive_labels = true, keyed by the same key as var.notification_channels"
  default     = {}
  sensitive   = true

  validation {
    condition     = alltrue([for v in values(var.notification_channel_sensitive_labels) : v.auth_token != null || v.password != null || v.service_key != null])
    error_message = "var.notification_channel_sensitive_labels entries must set at least one of auth_token, password or service_key"
  }
}

variable "alert_policies" {
  type = map(object({
    display_name          = string
    combiner              = optional(string, "OR")
    enabled               = optional(bool, true)
    severity              = string
    notification_channels = list(string)
    auto_close            = optional(string, "1800s")
    # Only used when the policy has a condition_matched_log condition.
    notification_rate_limit_period = optional(string, "300s")
    documentation = object({
      content   = string
      mime_type = optional(string, "text/markdown")
      subject   = optional(string)
    })
    conditions = list(object({
      display_name = string
      condition_threshold = optional(object({
        filter          = string
        comparison      = string
        threshold_value = number
        duration        = string
        aggregations = optional(list(object({
          alignment_period     = optional(string)
          per_series_aligner   = optional(string)
          cross_series_reducer = optional(string)
          group_by_fields      = optional(list(string))
        })), [])
      }))
      condition_matched_log = optional(object({
        filter           = string
        label_extractors = optional(map(string))
      }))
    }))
  }))
  description = "Map of alert policies. notification_channels entries are keys of var.notification_channels or full channel IDs. Each condition sets exactly one of condition_threshold or condition_matched_log; a log-match policy must have a single condition"
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : length(trimspace(v.display_name)) > 0 && length(trimspace(v.documentation.content)) > 0])
    error_message = "var.alert_policies display_name and documentation.content must be non-empty; responders need a runbook"
  }

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : contains(["CRITICAL", "ERROR", "WARNING"], v.severity)])
    error_message = "var.alert_policies severity must be one of CRITICAL, ERROR or WARNING"
  }

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : contains(["AND", "OR", "AND_WITH_MATCHING_RESOURCE"], v.combiner)])
    error_message = "var.alert_policies combiner must be one of AND, OR or AND_WITH_MATCHING_RESOURCE"
  }

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : length(v.notification_channels) > 0 && alltrue([for c in v.notification_channels : length(trimspace(c)) > 0])])
    error_message = "var.alert_policies must each route to at least one notification channel"
  }

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : can(regex("^[0-9]+s$", v.auto_close)) && can(regex("^[0-9]+s$", v.notification_rate_limit_period))])
    error_message = "var.alert_policies auto_close and notification_rate_limit_period must be durations in seconds, e.g. 1800s"
  }

  validation {
    condition     = alltrue(flatten([for v in values(var.alert_policies) : [length(v.conditions) > 0, [for c in v.conditions : (c.condition_threshold == null) != (c.condition_matched_log == null)]]]))
    error_message = "var.alert_policies must each have at least one condition, and each condition must set exactly one of condition_threshold or condition_matched_log"
  }

  validation {
    condition     = alltrue([for v in values(var.alert_policies) : length([for c in v.conditions : c if c.condition_matched_log != null]) == 0 || length(v.conditions) == 1])
    error_message = "var.alert_policies with a condition_matched_log condition must have exactly one condition (GCP restriction)"
  }

  validation {
    condition = alltrue(flatten([for v in values(var.alert_policies) : [for c in v.conditions : c.condition_threshold == null ? true : contains(
      ["COMPARISON_GT", "COMPARISON_GE", "COMPARISON_LT", "COMPARISON_LE", "COMPARISON_EQ", "COMPARISON_NE"], c.condition_threshold.comparison
    )]]))
    error_message = "var.alert_policies condition_threshold.comparison must be a COMPARISON_* value"
  }
}

variable "uptime_checks" {
  type = map(object({
    display_name     = string
    host             = string
    path             = optional(string, "/")
    port             = optional(number, 443)
    timeout          = optional(string, "10s")
    period           = optional(string, "60s")
    selected_regions = optional(list(string))
    content_matchers = optional(list(object({
      content = string
      matcher = optional(string, "CONTAINS_STRING")
    })), [])
    notification_channels = optional(list(string), [])
  }))
  description = "Map of HTTPS uptime checks against public hosts. SSL is always used and the certificate is always validated. Set notification_channels (keys of var.notification_channels or full channel IDs) to create an alert policy that fires when the check fails; without it the check alerts nobody"
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.uptime_checks) : length(trimspace(v.display_name)) > 0 && can(regex("^[A-Za-z0-9.-]+$", v.host)) && startswith(v.path, "/")])
    error_message = "var.uptime_checks display_name must be non-empty, host must be a bare hostname (no scheme or path) and path must start with /"
  }

  validation {
    condition     = alltrue([for v in values(var.uptime_checks) : contains(["60s", "300s", "600s", "900s"], v.period) && can(regex("^[0-9]+s$", v.timeout))])
    error_message = "var.uptime_checks period must be one of 60s, 300s, 600s or 900s, and timeout a duration in seconds"
  }

  validation {
    condition = alltrue(flatten([for v in values(var.uptime_checks) : [for m in v.content_matchers : length(m.content) > 0 && contains(
      ["CONTAINS_STRING", "NOT_CONTAINS_STRING", "MATCHES_REGEX", "NOT_MATCHES_REGEX"], m.matcher
    )]]))
    error_message = "var.uptime_checks content_matchers must have non-empty content and a matcher of CONTAINS_STRING, NOT_CONTAINS_STRING, MATCHES_REGEX or NOT_MATCHES_REGEX"
  }

  validation {
    condition     = alltrue(flatten([for v in values(var.uptime_checks) : [for c in v.notification_channels : length(trimspace(c)) > 0]]))
    error_message = "var.uptime_checks notification_channels entries must be non-empty"
  }
}

variable "dashboard_json" {
  type        = string
  description = "Optional Cloud Monitoring dashboard definition as JSON; no dashboard is created when null"
  default     = null

  validation {
    condition     = var.dashboard_json == null || can(jsondecode(var.dashboard_json))
    error_message = "var.dashboard_json must be valid JSON when set"
  }
}

variable "labels" {
  type        = map(string)
  description = "User labels applied to notification channels, alert policies and uptime checks"
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.labels : can(regex("^[a-z0-9_-]{1,63}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "var.labels keys and values must be lowercase alphanumerics, underscores, or hyphens, 1-63 characters (GCP label constraints)"
  }
}
