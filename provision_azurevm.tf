
# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "ff2ac935-150c-4854-8cb5-044cf21d224c"
    client_id       = "c7cf131d-7981-46ac-9f22-eeeb428844de"
    client_secret   = "28637766-8529-4d64-986e-767433c96c89"
    tenant_id       = "105b2061-b669-4b31-92ac-24d304d195dc"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "vm" {
    name     = "${var.resource_group_name}"
    location = "${var.location}"
    tags     = "${var.tags}"
}

resource "random_id" "vm-sa" {
  keepers = {
    vm_hostname = "${var.vm_hostname}"
  }

  byte_length = 6
}

# Create virtual network
resource "azurerm_virtual_network" "vm" {
    name                = "${var.vm_hostname}"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.vm.name}"
	tags                = "${var.tags}"
	
}

# Create subnet
resource "azurerm_subnet" "vm" {
    name                 = "terrasubnet"
    resource_group_name  = "${azurerm_resource_group.vm.name}"
    virtual_network_name = "${azurerm_virtual_network.vm.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "vm" {
    name                         = "${var.vm_hostname}-${count.index}-publicIP"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.vm.name}"
    public_ip_address_allocation = "${var.public_ip_address_allocation}"
    domain_name_label             = "${var.public_ip_dns}"

	
 
    tags                         = "${var.tags}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm" {
    name                = "${var.vm_hostname}-nsg"
    location            = "${azurerm_resource_group.vm.location}"
    resource_group_name = "${azurerm_resource_group.vm.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
	 security_rule {
        name                       = "http"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags                         = "${var.tags}"
}

# Create network interface
resource "azurerm_network_interface" "vm" {
    count                     = "${var.nb_instances}"
    name                      = "nic-${var.vm_hostname}-${count.index}"
    location                  = "${azurerm_resource_group.vm.location}"
    resource_group_name       = "${azurerm_resource_group.vm.name}"
    network_security_group_id = "${azurerm_network_security_group.vm.id}"

    ip_configuration {
        name                          = "ipconfig${count.index}"
        subnet_id                     = "${azurerm_subnet.vm.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.vm.id}"
    }

    
}


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "vm-sa" {
    name                        = "diag${random_id.vm-sa.hex}"
    resource_group_name         = "${azurerm_resource_group.vm.name}"
    location                    = "${var.location}"
    account_tier                = "${element(split("_", var.boot_diagnostics_sa_type),0)}"
    account_replication_type    = "${element(split("_", var.boot_diagnostics_sa_type),1)}"
    tags                     = "${var.tags}"
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "${var.vm_hostname}${count.index}"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.vm.name}"
    network_interface_ids = ["${element(azurerm_network_interface.vm.*.id, count.index)}"]
    vm_size               = "${var.vm_size}"

    storage_os_disk {
        name              = "datadisk-${var.vm_hostname}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.storage_account_type}"
    }

    storage_image_reference {
        publisher = "${var.os_publisher}"
        offer     = "${var.vm_os_offer}"
        sku       = "${var.vm_os_sku}"
        version   = "${var.vm_os_version}"
    }

    os_profile {
        computer_name  = "${var.vm_hostname}${count.index}"
        admin_username = "${var.admin_username}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.admin_username}/.ssh/authorized_keys"
            key_data = "${var.ssh_key}"
        }
    }
    tags = "${var.tags}"
    boot_diagnostics {
        enabled = "${var.boot_diagnostics}"
        storage_uri = "${var.boot_diagnostics == "true" ? join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint) : "" }"
    }

    
        
	
}
