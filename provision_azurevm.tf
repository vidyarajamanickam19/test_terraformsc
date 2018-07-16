
# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "cf90006e-4f4d-47e4-acb6-f21b0dec29ad"
    client_id       = "65720e53-8767-4987-be11-6e866a151dac"
    client_secret   = "df4e1e5f-1cba-44f4-a506-82f9e1a11dee"
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
    name                = "${var.vm_hostname}-${coalesce(var.remote_port,module.os.calculated_remote_port)}-nsg"
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
        name                       = "SSH"
        priority                   = 1001
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
