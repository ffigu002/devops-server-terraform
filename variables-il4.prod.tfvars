################################
### GLOBAL VARIABLES         ###
################################
location         = "usgovvirginia"
environment_type = "p" 
environment = "usgovernment"

metadata_host = "management.usgovcloudapi.net"
tier2_subid = "00000000-0000-0000-0000-000000000000"

domain_join_user = "domainjoin.user"
domain_name = "domain.local"

admin_username = "xadmin"

#################################
# Shared Services VNet
#################################
shared_services_resource_group_name = ""
hub_vnet_name = ""
devops_subnet_name = ""

#################################
# SQL
#################################
sql_admin_object_id = "00000000-0000-0000-0000-000000000000" #object ID of the SQL admin user
sql_admin_username  = "sql_admin_username" 

#################################
# Key Vault
#################################

shared_services_keyvault_name = "" # Name of the Key Vault 
domain_join_secret_name       = "domain-join-secret"

#################################
# Compute Gallery
#################################

shared_image_gallery_name = "sigcomputegallery" 
shared_image_name         = "devops_server_2022"

image_version = "sigcomputegallerypusgovva001/images/devops_server_2022/versions/1.0.1" #image must exist in the gallery

#################################
# VM
#################################
user_managed_identity_name = "msidevopspusgovva001" #managed identity name of the devops server VM

data_disks = [{
  name                 = "devops_server_vm_disk001"
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 256
  tier                 = "P40"
  create_option        = "Empty"
  lun                  = 1
  caching              = "None"
  }
]