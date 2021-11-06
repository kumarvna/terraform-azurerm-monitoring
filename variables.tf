variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "action_group" {
  description = "Manages an Action Group within Azure Monitor"
  type = object({
    name       = string
    short_name = string
    email_receiver = object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool)
    })
    webhook_receiver = object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool)
    })
  })
  default = null
}

variable "activity_log_alerts" {
  description = "Map of Activity log Alerts"
  type = map(object({
    description = string
    scopes      = list(string)
    criteria = object({
      category                = string
      operation_name          = optional(string)
      resource_provider       = optional(string)
      resource_type           = optional(string)
      resource_group          = optional(string)
      resource_id             = optional(string)
      level                   = optional(string)
      status                  = optional(string)
      sub_status              = optional(string)
      recommendation_type     = optional(string)
      recommendation_category = optional(string)
      recommendation_impact   = optional(string)
    })
  }))
  default = null
}

variable "service_health" {
  description = "A block to define fine grain service health settings"
  type        = map(string)
  default     = null
}


variable "metric_alerts" {
  description = "Manages a Metric Alerts within Azure Monitor"
  type = map(object({
    description              = string
    scopes                   = list(string)
    frequency                = optional(string)
    severity                 = optional(number)
    target_resource_type     = optional(string)
    target_resource_location = optional(string)
    window_size              = optional(string)
    criteria = optional(object({
      metric_namespace       = string
      metric_name            = string
      aggregation            = string
      operator               = string
      threshold              = number
      skip_metric_validation = optional(bool)
      dimension              = optional(map(string))
    }))
    dynamic_criteria = optional(object({
      metric_namespace         = string
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = string
      evaluation_total_count   = optional(number)
      evaluation_failure_count = optional(number)
      ignore_data_before       = optional(string)
      skip_metric_validation   = optional(bool)
      dimension = optional(object({
        name     = string
        operator = string
        values   = list(string)
      }))
    }))
  }))
  default = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
