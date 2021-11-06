locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------

data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge({ "Name" = format("%s", var.resource_group_name) }, var.tags, )
}

#------------------------------------------
# Azure Monitoring Action Group
#------------------------------------------
resource "azurerm_monitor_action_group" "action_group" {
  name                = format("%s", var.action_group.name)
  resource_group_name = local.resource_group_name
  short_name          = var.action_group.short_name
  tags                = merge({ "Name" = format("%s", var.action_group.name) }, var.tags, )

  dynamic "email_receiver" {
    for_each = var.action_group.email_receiver != null ? [var.action_group.email_receiver] : []
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = try(email_receiver.value.use_common_alert_schema, false)
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.action_group.webhook_receiver != null ? [var.action_group.webhook_receiver] : []
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = try(webhook_receiver.value.use_common_alert_schema, false)
    }
  }
}

#------------------------------------------
# Azure Monitor Activity Log Alerts
#------------------------------------------
resource "azurerm_monitor_activity_log_alert" "activity_log_alert" {
  for_each            = var.activity_log_alerts != null ? { for k, v in var.activity_log_alerts : k => v } : {}
  name                = format("%s-alert", each.key)
  description         = each.value.description
  resource_group_name = lookup(each.value, "resource_group_name", local.resource_group_name)
  scopes              = each.value.scopes
  tags                = merge({ "Name" = format("%s", var.action_group.name) }, var.tags, )

  criteria {
    category                = lookup(each.value.criteria, "category", "Recommendation")
    operation_name          = lookup(each.value.criteria, "operation_name", null)
    resource_provider       = lookup(each.value.criteria, "resource_provider", null)
    resource_type           = lookup(each.value.criteria, "resource_type", null)
    resource_group          = lookup(each.value.criteria, "resource_group", null)
    resource_id             = lookup(each.value.criteria, "resource_id", null)
    level                   = lookup(each.value.criteria, "level", "Error")
    status                  = lookup(each.value.criteria, "status", "Failed")
    sub_status              = lookup(each.value.criteria, "sub_status", null)
    recommendation_type     = each.value.criteria.category == "Recommendation" ? lookup(each.value.criteria, "recommendation_type") : null
    recommendation_category = each.value.criteria.category == "Recommendation" ? lookup(each.value.criteria, "recommendation_category") : null
    recommendation_impact   = each.value.criteria.category == "Recommendation" ? lookup(each.value.criteria, "recommendation_impact") : null

    dynamic "service_health" {
      for_each = var.service_health == null ? [] : [1]
      content {
        events    = lookup(var.service_health, "events", "Incident")
        locations = lookup(var.service_health, "locations", "Global")
        services  = lookup(var.service_health, "services", null)
      }
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
    webhook_properties = {
      from = "terraform"
    }
  }
}

resource "azurerm_monitor_metric_alert" "metric_alert" {
  for_each                 = var.metric_alerts != null ? { for k, v in var.metric_alerts : k => v } : {}
  name                     = format("%s-alert", each.key)
  description              = each.value.description
  resource_group_name      = lookup(each.value, "resource_group_name", local.resource_group_name)
  scopes                   = each.value.scopes
  frequency                = each.value.frequency
  severity                 = each.value.severity
  target_resource_type     = each.value.target_resource_type
  target_resource_location = each.value.target_resource_location
  window_size              = each.value.window_size
  tags                     = merge({ "Name" = format("%s", var.action_group.name) }, var.tags, )

  criteria {
    metric_namespace       = lookup(each.value.criteria, "metric_namespace")
    metric_name            = lookup(each.value.criteria, "metric_name")
    aggregation            = lookup(each.value.criteria, "aggregation")
    operator               = lookup(each.value.criteria, "operator")
    threshold              = lookup(each.value.criteria, "threshold")
    skip_metric_validation = lookup(each.value.criteria, "skip_metric_validation", false)

    /*     dynamic "dimension" {
      for_each = criteria.value.dimension != null ? [criteria.value.dimension] : []
      content {
        name     = dimension.value.name     #lookup(var.dimension, "name")
        operator = dimension.value.operator #lookup(var.dimension, "operator")
        values   = dimension.value.values   #lookup(var.dimension, "values")
      }
    } */
  }

  /* 
  dynamic "dynamic_criteria" {
    for_each = var.metric_alerts.dynamic_criteria != null ? [var.metric_alerts.dynamic_criteria] : []
    content {
      metric_namespace         = lookup(each.value.dynamic_criteria, "metric_namespace")
      metric_name              = lookup(each.value.dynamic_criteria, "metric_name")
      aggregation              = lookup(each.value.dynamic_criteria, "aggregation")
      operator                 = lookup(each.value.dynamic_criteria, "operator")
      alert_sensitivity        = lookup(each.value.dynamic_criteria, "alert_sensitivity")
      evaluation_total_count   = lookup(each.value.dynamic_criteria, "evaluation_total_count")
      evaluation_failure_count = lookup(each.value.dynamic_criteria, "evaluation_failure_count")
      ignore_data_before       = lookup(each.value.dynamic_criteria, "ignore_data_before")
      skip_metric_validation   = lookup(each.value.dynamic_criteria, "skip_metric_validation")

      dynamic "dimension" {
        for_each = dynamic_criteria.value.dimension != null ? [dynamic_criteria.value.dimension] : []
        content {
          name     = dimension.value.name     #lookup(var.dimension, "name")
          operator = dimension.value.operator #lookup(var.dimension, "operator")
          values   = dimension.value.values   #lookup(var.dimension, "values")
        }
      }
    }
  }
 */
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
    webhook_properties = {
      from = "terraform"
    }
  }
}
