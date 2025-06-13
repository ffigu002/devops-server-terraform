# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################
# Global Configuration
#################################

variable "random_seed" {
  description = "The random seed to use for the caf naming module to generate random characters (used in dev)"
  type        = number
  default     = 0
}

variable "random_length" {
  description = "The length of random characters to use for the caf naming module (used in dev)"
  type        = number
  default     = 0
}

variable "environment_type" {
  description = "The environment type (dev or prod)"
  type        = string
}

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  #   default     = "public"
}

variable "metadata_host" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com or management.usgovcloudapi.net."
  type        = string
}

variable "location" {
  description = "The Azure region for most Mission LZ resources. e.g. for government usgovvirginia"
  type        = string
  #   default     = "East US2"
}

# variable "resourcePrefix" {
#   description = "A name for the deployment. It defaults to mlz."
#   type        = string
#   default     = "mlz"
# }

variable "tags" {
  description = "A map of key value pairs to apply as tags to resources provisioned in this deployment"
  type        = map(string)
  default = {
    "DeploymentType" : "MissionLandingZoneTF"
  }
}

#################################
# Tier 2 Configuration
#################################

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
  type        = string
}

# variable "virtual_machine_extensions" {
#   type = map(object({
#     virtual_machine_name    = string
#     run_command_script_path = string
#     run_command_script_args = map(string)
#     custom_scripts = list(object({
#       name                 = string
#       command_to_execute   = string
#       file_uris            = list(string)
#       storage_account_name = string
#       resource_group_name  = string
#     }))
#     diagnostics_storage_config_path = string
#   }))
# }


# variable "windows_vm_id_map" { 
#   type = map(string)
# }

variable "shared_services_keyvault_name" {
  description = "The name of the shared services keyvault"
  type        = string
}

variable "shared_services_resource_group_name" {
  description = "The name of the shared services resource group"
  type        = string
}

variable "hub_vnet_name" {
  description = "The name of the Hub VNet"
  type        = string
}

variable "devops_subnet_name" {
  description = "The name of the Hub VNet"
  type        = string
}

variable "shared_image_gallery_name" {
  description = "The name of the compute gallery"
  type        = string
}

variable "shared_image_name" {
  description = "The name of the image"
  type        = string
}


# variable "windows_vm_name" {
#   description = "The name of the Windows jumpbox virtual machine"
#   type        = string
#   default     = "jumpboxWindowsVm"
# }

# variable "windows_vm_size" {
#   description = "The size of the Windows jumpbox virtual machine"
#   type        = string
#   #default     = "Standard_DS1_v2"
# }

# variable "windows_vm_publisher" {
#   description = "The publisher of the Windows jumpbox virtual machine source image"
#   type        = string
#   #default     = "MicrosoftWindowsServer"
# }

# variable "windows_vm_offer" {
#   description = "The offer of the Windows jumpbox virtual machine source image"
#   type        = string
#   #default     = "WindowsServer"
# }

# variable "windows_vm_sku" {
#   description = "The SKU of the Windows jumpbox virtual machine source image"
#   type        = string
#   #default     = "2019-datacenter-gensecond"
# }

# variable "windows_vm_version" {
#   description = "The version of the Windows jumpbox virtual machine source image"
#   type        = string
#   #default     = "latest"
# }

variable "admin_username" {
  description = "The admin username"
  type        = string
}

variable "sql_admin_object_id" {
  description = "The sql admin object id"
  type        = string
}

variable "sql_admin_username" {
  description = "The sql admin username"
  type        = string
}

variable "domain_join_user" {
  description = "domain join username"
  type        = string
}

variable "domain_name" {
  description = "domain name"
  type        = string
}

variable "image_version" {
  description = "image version"
  type        = string
}

variable "data_disks" {
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
    tier                 = string
    create_option        = string
    lun                  = number
    caching              = string
  }))
  default = []
}

variable "domain_join_secret_name" {
  description = "secret name to fetch from key vault"
  type        = string
}


variable "user_managed_identity_name" {
  description = "name of the user created managed identity"
  type        = string
}


