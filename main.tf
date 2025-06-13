# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  # It is recommended to use remote state instead of local
  # If you are using Terraform Cloud, You can update these values in order to configure your remote state.
  /*  backend "remote" {
    organization = "{{ORGANIZATION_NAME}}"
    workspaces {
      name = "{{WORKSPACE_NAME}}"
    }
  }
  */
  required_version = ">= 1.2.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.84"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.4.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.8.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.21"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}


provider "azurerm" {
  environment     = var.environment
  #metadata_host   = var.metadata_host
  subscription_id = var.tier2_subid

  skip_provider_registration = true

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "random" {
}

provider "time" {
}

data "azurerm_client_config" "current_client" {
}

data "azurerm_key_vault" "shared_services_kv" {
  name                = var.shared_services_keyvault_name
  resource_group_name = var.shared_services_resource_group_name
}

data "azurerm_virtual_network" "shared_services_vnet" {
  name                = var.hub_vnet_name                       #var.hub_vnetname
  resource_group_name = var.shared_services_resource_group_name #var.hub_rgname
}

data "azurerm_subnet" "devops_subnet" {
  name                 = var.devops_subnet_name
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.shared_services_resource_group_name
}

data "azurerm_shared_image_gallery" "compute_gallery" {
  name                = var.shared_image_gallery_name
  resource_group_name = var.shared_services_resource_group_name
}

data "azurerm_shared_image" "existing" {
  name                = var.shared_image_name
  gallery_name        = data.azurerm_shared_image_gallery.compute_gallery.name
  resource_group_name = var.shared_services_resource_group_name
}

data "azurerm_key_vault_secret" "domain_join_secret" {
  name         = var.domain_join_secret_name #"domain-join-secret"
  key_vault_id = data.azurerm_key_vault.shared_services_kv.id
}

################################
### GLOBAL VARIABLES         ###
################################

locals {

  environment   = var.environment_type
  workload      = "devopssrv"
  random_length = var.random_length
  clean_input   = true
  location      = var.location
  random_seed   = var.random_seed
  index         = "001"
}

################################
### CAF Naming Standard      ###
################################

### RG DevOps Name
module "rg_devops_name" {
  source        = "../../modules/caf-naming-standard"
  resource_type = "azurerm_resource_group"
  naming_standard = {
    name           = "devops"
    prefixes       = null
    suffixes       = [local.environment, var.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = local.index
  }
}

### VM names
module "devops_base_vm_name" {
  source        = "../../modules/caf-naming-standard"
  resource_type = "azurerm_windows_virtual_machine"
  naming_standard = {
    name           = "devops-base-vm"
    prefixes       = null
    suffixes       = [local.environment, local.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = "001"
  }
}

module "devops_server_vm_name" {
  source        = "../../modules/caf-naming-standard"
  resource_type = "azurerm_windows_virtual_machine"
  naming_standard = {
    name           = "devops-server2022"
    prefixes       = null
    suffixes       = [local.environment, local.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = "001"
  }
}

module "devops_vm_user_mi" {
  source        = "../../modules/caf-naming-standard"
  resource_type = "azurerm_user_assigned_identity"
  naming_standard = {
    name           = "devops"
    prefixes       = null
    suffixes       = [local.environment, local.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = "001"
  }
}


module "sql_server_name" {
  source        = "../../modules/caf-naming-standard"
  resource_type = "azurerm_sql_server"
  naming_standard = {
    name           = "devops"
    prefixes       = null
    suffixes       = [local.environment, local.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = "001"
  }
}


resource "azurerm_resource_group" "devops_rg" {
  location = var.location
  name     = module.rg_devops_name.name

}

resource "random_integer" "devops-base-vm-password" {
  provider = random
  min      = 12
  max      = 72
}

resource "random_password" "devops-base-vm-password" {
  provider    = random
  length      = random_integer.devops-base-vm-password.result
  upper       = true
  lower       = true
  number      = true
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}


resource "azurerm_key_vault_secret" "devops-base-vm-password" {
  name         = "${module.windows-base-virtual-machine2.virtual_machine_name}-password" #"base-vm-password"
  value        = random_password.devops-base-vm-password.result
  key_vault_id = data.azurerm_key_vault.shared_services_kv.id
}

module "windows-base-virtual-machine2" {
  source = "../../modules/windows-virtual-machine"

  naming_standard = {
    name           = "devops-basev2"
    prefixes       = null
    suffixes       = [local.environment, azurerm_resource_group.devops_rg.location]
    random_length  = local.random_length
    clean_input    = local.clean_input
    location       = local.location
    random_seed    = local.random_seed
    instance_index = local.index
  }


  resource_group_name  = azurerm_resource_group.devops_rg.name
  location             = var.location
  virtual_network_name = data.azurerm_virtual_network.shared_services_vnet.name #module.spoke-network-t3.virtual_network_name
  virtual_network_rg   = var.shared_services_resource_group_name
  subnet_name          = var.devops_subnet_name
  name                 = module.devops_base_vm_name.name
  size                 = "Standard_DS3_v2"
  admin_username       = "xadmin"
  admin_password       = random_password.devops-base-vm-password.result
  publisher            = "MicrosoftWindowsServer"    #var.windows_vm_publisher
  offer                = "WindowsServer"             #var.windows_vm_offer
  sku                  = "2019-datacenter-gensecond" #var.windows_vm_sku
  image_version        = "latest"

  tags = var.tags
  #enable_accelerated_networking = true

  vtpm_enabled        = true
  secure_boot_enabled = true
  #laws_workspace_id = data.azurerm_log_analytics_workspace.laws.workspace_id
  #laws_primary_shared_key = data.azurerm_log_analytics_workspace.laws.primary_shared_key

}

resource "azurerm_shared_image_version" "devops_image_versionv2" {
  count               = var.environment_type == "p" ? 1 : 0 #VM must be generalized before creating the image
  name                = "1.0.1"
  gallery_name        = data.azurerm_shared_image_gallery.compute_gallery.name
  image_name          = data.azurerm_shared_image.existing.name
  resource_group_name = data.azurerm_shared_image_gallery.compute_gallery.resource_group_name
  location            = data.azurerm_shared_image.existing.location
  managed_image_id    = module.windows-base-virtual-machine2.virtual_machine_id

  target_region {
    name                   = data.azurerm_shared_image.existing.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
  deletion_of_replicated_locations_enabled = true


}

resource "azurerm_user_assigned_identity" "user_managed_identity" {
  location            = var.location
  name                = var.user_managed_identity_name #must not have hyphens in the name
  resource_group_name = azurerm_resource_group.devops_rg.name
}

resource "azurerm_key_vault_access_policy" "kv_access_policy" {

  key_vault_id = data.azurerm_key_vault.shared_services_kv.id
  tenant_id    = data.azurerm_client_config.current_client.tenant_id
  object_id    = azurerm_user_assigned_identity.user_managed_identity.principal_id

  key_permissions = [
    "Create",
    "Get",
  ]

  secret_permissions = [
    "Set",
    "Get",
    "List",
    "Delete",
    "Purge",
    "Recover"
  ]
}


##DevOps VM Secret
resource "random_integer" "devops-vm-password" {
  min = 6
  max = 123
}

resource "random_password" "devops-vm-password" {
  length      = random_integer.devops-vm-password.result
  upper       = true
  lower       = true
  numeric     = true
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "devops-vm-password" {
  name         = "devops-server-vm-password"
  value        = random_password.devops-vm-password.result
  key_vault_id = data.azurerm_key_vault.shared_services_kv.id
}

#Azure SQL Admin Secret

resource "random_integer" "azure-sql-password" {
  min = 6
  max = 123
}

resource "random_password" "azure-sql-password" {
  length      = random_integer.azure-sql-password.result
  upper       = true
  lower       = true
  numeric     = true
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "azure-sql-password" {
  name         = "azure-sql-password"
  value        = random_password.azure-sql-password.result
  key_vault_id = data.azurerm_key_vault.shared_services_kv.id
}


resource "azurerm_resource_group_template_deployment" "terraform-arm" {
  count               = var.environment_type == "p" ? 1 : 0
  name                = "terraform-arm-01"
  resource_group_name = azurerm_resource_group.devops_rg.name
  deployment_mode     = "Incremental"

  template_content = file("azuredeploy.json")


  parameters_content = jsonencode({
    "sqlServerName"                  = { value = module.sql_server_name.name } 
    "sqlAdminUsername"               = { value = var.admin_username }
    "sqlAdminPassword"               = { value = random_password.azure-sql-password.result }
    "sqlAADAdminUsername"            = { value = var.sql_admin_username }
    "sqlAADAdminObjectID"            = { value = var.sql_admin_object_id }
    "keyVaultSQLAADAdmin"            = { value = data.azurerm_key_vault.shared_services_kv.name } 
    "virtualMachineName"             = { value = module.devops_server_vm_name.name }
    "localVMAdminUsername"           = { value = var.admin_username }
    "localVMAdminPassword"           = { value = random_password.devops-vm-password.result }
    "domainUsername"                 = { value = var.domain_join_user }
    "domainPassword"                 = { value = data.azurerm_key_vault_secret.domain_join_secret.value }
    "domainToJoin"                   = { value = var.domain_name }
    "vmManagedIdentity"              = { value = azurerm_user_assigned_identity.user_managed_identity.name }
    "vmManagedIdentityResourceGroup" = { value = azurerm_resource_group.devops_rg.name }
    "vmDevOpsImageName"              = { value = var.image_version }
    "vmDevOpsImageResourceGroup"     = { value = var.shared_services_resource_group_name }
    "fileUris"                       = { value = "" }
    "virtualNetworkName"             = { value = var.hub_vnet_name }
    "virtualNetworkResourceGroup"    = { value = var.shared_services_resource_group_name }
    "virtualNetworkSubnetName"       = { value = var.devops_subnet_name }
  })


  lifecycle {
    ignore_changes = all
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk
resource "azurerm_managed_disk" "ManagedDisk" {
  for_each             = { for data_disk in var.data_disks : data_disk.name => data_disk }
  resource_group_name  = azurerm_resource_group.devops_rg.name
  name                 = each.value.name
  location             = var.location
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb
  tier                 = each.value.tier
  depends_on           = [azurerm_resource_group_template_deployment.terraform-arm]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment
resource "azurerm_virtual_machine_data_disk_attachment" "ManagedDiskAttachment" {
  for_each           = { for data_disk in var.data_disks : data_disk.name => data_disk }
  managed_disk_id    = azurerm_managed_disk.ManagedDisk[each.key].id
  virtual_machine_id = "/subscriptions/${var.tier2_subid}/resourceGroups/${azurerm_resource_group.devops_rg.name}/providers/Microsoft.Compute/virtualMachines/${module.devops_server_vm_name.name}" #azurerm_windows_virtual_machine.windows_vm.id
  lun                = each.value.lun
  caching            = each.value.caching
  depends_on         = [azurerm_resource_group_template_deployment.terraform-arm]
}

##Enable Run Command Extension on Azure Windows VM, MUST give Directory Reader role to the Azure SQL MI created above
resource "azurerm_virtual_machine_extension" "run_command" {
  count                      = var.environment_type == "p" ? 1 : 0
  name                       = "run-command"
  virtual_machine_id         = "/subscriptions/${var.tier2_subid}/resourceGroups/${azurerm_resource_group.devops_rg.name}/providers/Microsoft.Compute/virtualMachines/${module.devops_server_vm_name.name}"
  publisher                  = "Microsoft.CPlat.Core"
  type                       = "RunCommandWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    script = split("\n", templatefile("${path.root}//scripts/configureSQL.ps1", { username = "${var.sql_admin_object_id}@${data.azurerm_client_config.current_client.tenant_id}", targetsrv = module.sql_server_name.name, keyVaultName = data.azurerm_key_vault.shared_services_kv.name, managedIdentity = azurerm_user_assigned_identity.user_managed_identity.name }))
  })

  depends_on = [azurerm_resource_group_template_deployment.terraform-arm]
}




