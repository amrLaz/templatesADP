# Declare azurerm and azuredevops providers with specific versions
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"

    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1"

    }
  }
}

provider "azuredevops" {
  # org_service_url = var.AZDO_ORG_SERVICE_URL
  # personal_access_token = var.AZDO_PERSONAL_ACCESS_TOKEN
  # org_service_url       = "https://dev.azure.com/GroupeADP"
  # personal_access_token = "sph4fn2ghavfcwezkssbxhpya5kmsy3o4cnlyonmqo2ebv3pydca"
}
provider "azurerm" {
  features {}
}

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "az-11-dev-rg-back-00001"
#     storage_account_name = "az11devstback00001"
#     container_name       = "tfstate"
#     key                  = "backend/temptest/devopsproject/terraform.tfstate"
#   }
# }

#declare locla variables
locals {
  project_name    = "N0001"
  project_process = "ADP_Scrum"
  repositories = {
    repos1 = "REPO1"
    repos2 = "REPO2"
    repos3 = "REPO3"
  }
  teams = {
    team1 = "TEAM1"
    team2 = "TEAM2"
    team3 = "TEAM3"
  }
  groups = {
    admin = "Administrators"
    dev   = "Developpers"
  }

  service_connections = {
    dev = {
      PID       = ""
      PKEY      = ""
      SUB_ID    = "0c0a17eb-1b97-48da-b1ee-1af554360d02"
      SUB_NAME  = "ADP-DEV_DSIO_CCOE"
      TENANT_ID = "fb28acc8-b04d-4b2f-8389-51e8561ca6d8"
    }
    val = {
      PID       = ""
      PKEY      = ""
      EP_NAME   = "val-Service-Connection"
      SUB_ID    = "0c0a17eb-1b97-48da-b1ee-1af554360d02"
      SUB_NAME  = "ADP-DEV_DSIO_CCOE"
      TENANT_ID = "fb28acc8-b04d-4b2f-8389-51e8561ca6d8"
    }
    prd = {
      PID       = ""
      PKEY      = ""
      EP_NAME   = "prd-Service-Connection"
      SUB_ID    = "0c0a17eb-1b97-48da-b1ee-1af554360d02"
      SUB_NAME  = "ADP-DEV_DSIO_CCOE"
      TENANT_ID = "fb28acc8-b04d-4b2f-8389-51e8561ca6d8"
    }
  }
}


# Create Azure DevOps project if it doesn't exist
# data "azuredevops_project" "existing_project" {
#   name = "N0001"
# }


resource "azuredevops_project" "new_project" {
  name               = local.project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = local.project_process
  description        = "Managed by Terraform"
  # depends_on         = [data.azuredevops_project.existing_project]
  features = {
    "testplans" = "disabled"
    "artifacts" = "disabled"
  }
}


#Define Repos
resource "azuredevops_git_repository" "example" {
  for_each   = local.repositories
  project_id = azuredevops_project.new_project.id
  name       = each.value
  initialization {
    init_type = "Clean"
  }
}

# Define groups (administrators, contributors,  readers ...) 
resource "azuredevops_group" "groups" {
  for_each     = local.groups
  scope        = azuredevops_project.new_project.id
  display_name = each.value
}


# Create teams
resource "azuredevops_team" "project_team" {
  for_each   = local.teams
  project_id = azuredevops_project.new_project.id
  name       = each.value
}

#Assign team administrators
resource "azuredevops_team_administrators" "team-administrators" {
  for_each   = local.teams
  project_id = azuredevops_project.new_project.id
  team_id    = azuredevops_team.project_team[each.key].id
  mode       = "overwrite"
  administrators = [
    azuredevops_group.groups["admin"].descriptor
  ]
}

#Add Project pesmissions
resource "azuredevops_project_permissions" "admin-permission" {
  project_id = azuredevops_project.new_project.id
  principal  = azuredevops_group.groups["admin"].id
  permissions = {
    DELETE                       = "Deny"
    GENERIC_WRITE                = "Deny"
    RENAME                       = "Deny"
    CHANGE_PROCESS               = "Deny"
    UPDATE_VISIBILITY            = "Deny"
    EDIT_BUILD_STATUS            = "Allow"
    WORK_ITEM_MOVE               = "Allow"
    DELETE_TEST_RESULTS          = "Deny"
    WORK_ITEM_DELETE             = "Deny"
    WORK_ITEM_PERMANENTLY_DELETE = "Deny"
  }
}

resource "azuredevops_project_permissions" "dev-permission" {
  project_id = azuredevops_project.new_project.id
  principal  = azuredevops_group.groups["dev"].id
  permissions = {
    DELETE                       = "Deny"
    GENERIC_WRITE                = "Deny"
    RENAME                       = "Deny"
    CHANGE_PROCESS               = "Deny"
    UPDATE_VISIBILITY            = "Deny"
    EDIT_BUILD_STATUS            = "Deny"
    WORK_ITEM_MOVE               = "Allow"
    DELETE_TEST_RESULTS          = "Deny"
    WORK_ITEM_DELETE             = "Deny"
    WORK_ITEM_PERMANENTLY_DELETE = "Deny"
    START_BUILD                  = "Allow"


  }
}


# resource "azuredevops_serviceendpoint_azurerm" "example" {
#   for_each            = local.service_connections
#   project_id            = azuredevops_project.new_project.id
#   service_endpoint_name = "Example AzureRM"
#   description           = "Managed by Terraform"
#   credentials {
#     serviceprincipalid  = each.value.PID
#     serviceprincipalkey = each.value.PKEY
#   }
#   azurerm_spn_tenantid      = each.value.TENANT_ID
#   azurerm_subscription_id   = each.value.SUB_ID
#   azurerm_subscription_name = each.value.SUB_NAME
# }

#Create Variable group
resource "azuredevops_variable_group" "vargroup" {
  project_id   = azuredevops_project.new_project.id
  name         = "GroupVar"
  description  = "This VAriable group includes variables from azure keyvault called through the key_vault block below"
  allow_access = true

  # Add keyvault to link secrets from as variables in azure pipelines
  # key_vault {
  #   name                = "example-kv"
  #   service_endpoint_id = azuredevops_serviceendpoint_azurerm.serviceconnection.id
  # }

  variable {
    name = "key1"
  }

  variable {
    name      = "key2"
    is_secret = true
  }
}

