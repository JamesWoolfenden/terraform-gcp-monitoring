# terraform-gcp-monitoring

[![Build Status](https://github.com/JamesWoolfenden/terraform-gcp-monitoring/workflows/Verify/badge.svg?branch=main)](https://github.com/JamesWoolfenden/terraform-gcp-monitoring/actions)
[![Latest Release](https://img.shields.io/github/release/JamesWoolfenden/terraform-gcp-monitoring.svg)](https://github.com/JamesWoolfenden/terraform-gcp-monitoring/releases/latest)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/JamesWoolfenden/terraform-gcp-monitoring.svg?label=latest)](https://github.com/JamesWoolfenden/terraform-gcp-monitoring/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D1.5.0-blue.svg)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

Terraform module for Cloud Monitoring. Creates a map of notification channels (email, Pub/Sub, webhook; credentials passed via sensitive_labels, and a publisher grant for the monitoring notification agent on Pub/Sub channel topics), alert policies with metric-threshold or log-match conditions (documentation, severity, notification channels and auto-close required), HTTPS uptime checks that always validate SSL with optional content matchers, and an optional dashboard from JSON.

## Usage

Add **module.monitoring.tf** to your code:-

```terraform
module "monitoring" {
  source = "jameswoolfenden/monitoring/gcp"

  notification_channels = {
    oncall = {
      type         = "email"
      display_name = "Platform on-call"
      labels       = { email_address = "oncall@example.com" }
    }
  }

  alert_policies = {
    high-cpu = {
      display_name          = "High CPU utilisation"
      severity              = "WARNING"
      notification_channels = ["oncall"]
      documentation         = { content = "CPU above 80% for 5 minutes; check the workload and scale out." }
      conditions = [{
        display_name = "VM CPU above 80%"
        condition_threshold = {
          filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
          comparison      = "COMPARISON_GT"
          threshold_value = 0.8
          duration        = "300s"
        }
      }]
    }
  }

  uptime_checks = {
    homepage = {
      display_name = "Homepage HTTPS"
      host         = "example.com"
    }
  }
}
```

See [example/examplea](example/examplea) for a complete working example.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_monitoring_alert_policy.log_match](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.threshold](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_dashboard.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_dashboard) | resource |
| [google_monitoring_notification_channel.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_notification_channel) | resource |
| [google_monitoring_uptime_check_config.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config) | resource |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_pubsub_topic_iam_member.notification_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alert_policies"></a> [alert\_policies](#input\_alert\_policies) | Map of alert policies. notification\_channels entries are keys of var.notification\_channels or full channel IDs. Each condition sets exactly one of condition\_threshold or condition\_matched\_log; a log-match policy must have a single condition | <pre>map(object({display_name = string combiner = optional(string, "OR") enabled = optional(bool, true) severity = string notification_channels = list(string) auto_close = optional(string, "1800s") notification_rate_limit_period = optional(string, "300s") documentation = object({content = string mime_type = optional(string, "text/markdown") subject = optional(string)}) conditions = list(object({display_name = string condition_threshold = optional(object({filter = string comparison = string threshold_value = number duration = string aggregations = optional(list(object({alignment_period = optional(string) per_series_aligner = optional(string) cross_series_reducer = optional(string) group_by_fields = optional(list(string))})), [])})) condition_matched_log = optional(object({filter = string label_extractors = optional(map(string))}))}))}))</pre> | `{}` | no |
| <a name="input_dashboard_json"></a> [dashboard\_json](#input\_dashboard\_json) | Optional Cloud Monitoring dashboard definition as JSON; no dashboard is created when null | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | User labels applied to notification channels, alert policies and uptime checks | `map(string)` | `{}` | no |
| <a name="input_notification_channel_sensitive_labels"></a> [notification\_channel\_sensitive\_labels](#input\_notification\_channel\_sensitive\_labels) | Credentials for notification channels with has\_sensitive\_labels = true, keyed by the same key as var.notification\_channels | <pre>map(object({auth_token = optional(string) password = optional(string) service_key = optional(string)}))</pre> | `{}` | no |
| <a name="input_notification_channels"></a> [notification\_channels](#input\_notification\_channels) | Map of notification channels to create. type is email (labels.email\_address), pubsub (labels.topic, a full projects/P/topics/T ID), webhook\_tokenauth (labels.url) or webhook\_basicauth (labels.url, labels.username). Set has\_sensitive\_labels to read credentials for the channel from var.notification\_channel\_sensitive\_labels. | <pre>map(object({type = string display_name = string description = optional(string) labels = map(string) enabled = optional(bool, true) has_sensitive_labels = optional(bool, false)}))</pre> | `{}` | no |
| <a name="input_uptime_checks"></a> [uptime\_checks](#input\_uptime\_checks) | Map of HTTPS uptime checks against public hosts. SSL is always used and the certificate is always validated | <pre>map(object({display_name = string host = string path = optional(string, "/") port = optional(number, 443) timeout = optional(string, "10s") period = optional(string, "60s") selected_regions = optional(list(string)) content_matchers = optional(list(object({content = string matcher = optional(string, "CONTAINS_STRING")})), [])}))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alert_policy_ids"></a> [alert\_policy\_ids](#output\_alert\_policy\_ids) | Map of alert policy key to alert policy ID |
| <a name="output_dashboard_id"></a> [dashboard\_id](#output\_dashboard\_id) | ID of the dashboard, or null when var.dashboard\_json is not set |
| <a name="output_notification_channel_ids"></a> [notification\_channel\_ids](#output\_notification\_channel\_ids) | Map of notification channel key to channel ID |
| <a name="output_uptime_check_ids"></a> [uptime\_check\_ids](#output\_uptime\_check\_ids) | Map of uptime check key to uptime check ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Role and Permissions

<!-- BEGINNING OF PRE-COMMIT-PIKE DOCS HOOK -->
The Terraform resource required is:

```golang
# apply role
resource "google_project_iam_custom_role" "terraform_pike" {
  project     = "pike-477416"
  role_id     = "terraform_pike"
  title       = "terraform_pike"
  description = "A user with least privileges"
  permissions = [
    "monitoring.alertPolicies.create",
    "monitoring.alertPolicies.delete",
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.update",
    "monitoring.dashboards.create",
    "monitoring.dashboards.delete",
    "monitoring.dashboards.get",
    "monitoring.dashboards.update",
    "monitoring.notificationChannels.create",
    "monitoring.notificationChannels.delete",
    "monitoring.notificationChannels.get",
    "monitoring.notificationChannels.update",
    "monitoring.uptimeCheckConfigs.create",
    "monitoring.uptimeCheckConfigs.delete",
    "monitoring.uptimeCheckConfigs.get",
    "monitoring.uptimeCheckConfigs.update",
    "pubsub.topics.getIamPolicy",
    "pubsub.topics.setIamPolicy",
    "resourcemanager.projects.get"
  ]
}

# plan role
resource "google_project_iam_custom_role" "terraform_pike_plan" {
  project     = "pike-477416"
  role_id     = "terraform_pike_plan"
  title       = "terraform_pike_plan"
  description = "A user with least privileges"
  permissions = [
    "monitoring.alertPolicies.get",
    "monitoring.dashboards.get",
    "monitoring.notificationChannels.get",
    "monitoring.uptimeCheckConfigs.get",
    "pubsub.topics.getIamPolicy",
    "resourcemanager.projects.get"
  ]
}


```
<!-- END OF PRE-COMMIT-PIKE DOCS HOOK -->

## Help

**Got a question?**

File a GitHub [issue](https://github.com/jameswoolfenden/terraform-gcp-monitoring/issues).

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/jameswoolfenden/terraform-gcp-monitoring/issues) to report any bugs or file feature requests.

## Copyrights

Copyright © 2026 James Woolfenden

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

<https://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.

### Contributors

[![James Woolfenden][jameswoolfenden_avatar]][jameswoolfenden_homepage]<br/>[James Woolfenden][jameswoolfenden_homepage]

[jameswoolfenden_homepage]: https://github.com/jameswoolfenden
[jameswoolfenden_avatar]: https://github.com/jameswoolfenden.png?size=150
