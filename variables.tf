variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "terraformRG"
}
variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default = "eastus"
}
variable "tags" {
  type        = "map"
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "vm_hostname" {
  description = "local name of the VM"
  default     = "Terraformvm"
}

variable "public_ip_address_allocation" {
  description = "Defines how an IP address is assigned. Options are Static or Dynamic."
  default     = "dynamic"
}
variable "public_ip_dns" {
  description = "Optional globally unique per datacenter region domain name label to apply to each public ip address. e.g. thisvar.varlocation.cloudapp.azure.com where you specify only thisvar here. This is an array of names which will pair up sequentially to the number of public ips defined in var.nb_public_ip. One name or empty string is required for every public ip. If no public ip is desired, then set this to an array with a single empty string."
  default     = "terraformvm"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_DS1_V2"
}
variable "data_disk_size_gb" {
  description = "Storage data disk size size"
  default     = "2GB"
}
variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options are Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS."
  default     = "Premium_LRS"
}
variable "os_publisher" {
  description = "Defines the publisher"
  default     = "Canonical"
}
variable "vm_os_offer" {
  description = "The name of the offer of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "UbuntuServer"
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "16.04.0-LTS"
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. This is ignored when vm_os_id or vm_os_simple are provided."
  default     = "latest"
}
variable "admin_username" {
  description = "The admin username of the VM that will be deployed"
  default     = "dxccnaadmin"
}
variable "ssh_key" {
  description = "Path to the public key to be used for ssh access to the VM.  Only used with non-Windows vms and can be left as-is even if using Windows vms. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub"
  default     = "home/dxccnaadmin/.ssh/id_rsa.pub"
}
variable "boot_diagnostics" {
  description = "(Optional) Enable or Disable boot diagnostics"
  default     = "false"
}

variable "nb_instances" {
  description = "Specify the number of vm instances"
  default     = "1"
}
variable "boot_diagnostics_sa_type" {
  description = "(Optional) Storage account type for boot diagnostics"
  default     = "Standard_LRS"
}






