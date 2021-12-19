provider "azurerm" {
  features {
  }
}

module "monitoring" {
  //  source  = "kumarvna/monitoring/azurerm"
  //  version = "2.3.0"
  source = "../../"

  # By default, this module will not create a resource group and expect to provide 
  # a existing RG name to use an existing resource group. Location will be same as existing RG. 
  # set the argument to `create_resource_group = true` to create new resrouce.
  resource_group_name = "rg-shared-westeurope-01"
  location            = "westeurope"


  action_group = {
    name       = "example-action-group"
    short_name = "expaag"
    email_receiver = {
      email_address           = "monitoringusers@example.com"
      name                    = "monitoring-team"
      use_common_alert_schema = false
    }
    webhook_receiver = {
      name                    = "ServiceNow"
      service_uri             = "https://Event_Management_Azure:KSRQYCYkWY4wKm2uSA@tieto.service-now.com/api/global/em/inbound_event?source=AzureLogAnalyticsEvent"
      use_common_alert_schema = false
    }
  }


  activity_log_alerts = {
    "backup_health_event-Critical" = {
      description = "The count of health events pertaining to backup job health"
      scopes      = ["/subscriptions/5a0855b9-426d-429e-83a9-ea7c4796e9a4/resourceGroups/example-resources/providers/Microsoft.RecoveryServices/vaults/examplevault002"]
      criteria = {
        category = "Administrative"
        status   = "Failed"
      }
    }
  }

  metric_alerts = {
    "Used_Capacity-Critical" = {
      description = "The percentage use of a storage account"
      frequency   = "PT5M"
      severity    = 0
      scopes      = [data.azurerm_storage_account.example.id]
      window_size = "PT6H"
      criteria = {
        metric_namespace = "Microsoft.Storage/StorageAccounts"
        metric_name      = "UsedCapacity"
        aggregation      = "Average"
        operator         = "GreaterThan"
        threshold        = 4947802324992 #Alert will be triggered once it's breach 90% of threshold
      }
    },
  }

  # Adding additional TAG's to your Azure resources
  tags = {
    ProjectName  = "demo-project"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}

data "azurerm_storage_account" "example" {
  name                = "stdiagfortesting"
  resource_group_name = "rg-shared-westeurope-01"
}
