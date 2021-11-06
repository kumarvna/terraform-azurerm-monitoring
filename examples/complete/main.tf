provider "azurerm" {
  features {
  }
}

module "monitoring" {
  //  source  = "kumarvna/monitoring/azurerm"
  //  version = "2.3.0"
  source = "../../"

  # Resource Group, location, VNet and Subnet details
  resource_group_name = "rg-shared-westeurope-01"
  location            = "westeurope"


  action_group = {
    name       = "fs-metsa-action-group"
    short_name = "metsaag"
    email_receiver = {
      email_address           = "public-cloud-ms-india@tietoevry.com"
      name                    = "public-cloud-ms-team"
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

  # Adding additional TAG's to your Azure resources
  tags = {
    ProjectName  = "demo-project"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
