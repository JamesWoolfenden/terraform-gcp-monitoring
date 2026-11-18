# holden:ignore:HLD_TF_026 — examples intentionally use ../../ to reference the local module root
module "monitoring" {
  source = "../../"

  labels = {
    team = "platform"
  }

  notification_channels = {
    oncall = {
      type         = "email"
      display_name = "Platform on-call"
      labels = {
        email_address = var.alert_email
      }
    }
  }

  alert_policies = {
    high-cpu = {
      display_name          = "High CPU utilisation"
      severity              = "WARNING"
      notification_channels = ["oncall"]
      documentation = {
        subject = "High CPU on $${resource.label.instance_id}"
        content = "CPU utilisation has been above 80% for 5 minutes. Check the instance's workload and scale out if sustained."
      }
      conditions = [{
        display_name = "VM CPU above 80%"
        condition_threshold = {
          filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
          comparison      = "COMPARISON_GT"
          threshold_value = 0.8
          duration        = "300s"
          aggregations = [{
            alignment_period   = "60s"
            per_series_aligner = "ALIGN_MEAN"
          }]
        }
      }]
    }
  }

  uptime_checks = {
    homepage = {
      display_name = "Homepage HTTPS"
      host         = var.uptime_host
      content_matchers = [{
        content = "Example Domain"
      }]
    }
  }
}
