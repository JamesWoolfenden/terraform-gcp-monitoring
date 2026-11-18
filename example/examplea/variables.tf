variable "alert_email" {
  type        = string
  description = "Email address that receives alert notifications"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "var.alert_email must be a valid email address"
  }
}

variable "uptime_host" {
  type        = string
  description = "Public hostname probed by the uptime check"

  validation {
    condition     = can(regex("^[A-Za-z0-9.-]+$", var.uptime_host))
    error_message = "var.uptime_host must be a bare hostname"
  }
}
