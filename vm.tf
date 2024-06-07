# # Network Interface for Public VM
# resource "azurerm_network_interface" "ecomm-public-nic" {
#   name                = "ecomm-public-nic"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.ecomm-public-subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.ecomm-public-ip.id
#   }
# }

# # Network Interface for Private VM
# resource "azurerm_network_interface" "ecomm-private-nic" {
#   name                = "ecomm-private-nic"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.ecomm-private-subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Public Virtual Machine
# resource "azurerm_linux_virtual_machine" "ecomm-public-vm" {
#   name                = "ecomm-public-vm"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   size                = "Standard_B1s"
#   admin_username      = "adminuser"
#   admin_password      = "S@i1234!"  
#   disable_password_authentication = false  # Enable password authentication
#   network_interface_ids = [azurerm_network_interface.ecomm-public-nic.id]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "20_04-lts"  # Use Ubuntu 20.04
#     version   = "latest"
#   }

#   tags = {
#     Name = "ecomm-public-vm"
#   }
# }

# # Private Virtual Machine
# resource "azurerm_linux_virtual_machine" "ecomm-private-vm" {
#   name                = "ecomm-private-vm"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   size                = "Standard_B1s"
#   admin_username      = "adminuser"
#   admin_password      = "S@i1234!"  
#   disable_password_authentication = false  # Enable password authentication
#   network_interface_ids = [azurerm_network_interface.ecomm-private-nic.id]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "20_04-lts"  # Use Ubuntu 20.04
#     version   = "latest"
#   }

#   tags = {
#     Name = "ecomm-private-vm"
#   }
# }


# Public Virtual Machine
resource "azurerm_linux_virtual_machine" "ecomm-vm" {
  name                = "ecomm-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "adminuser1"
  admin_password      = "S@i1234!"
  disable_password_authentication = false  # Enable password authentication
  network_interface_ids = [
    azurerm_network_interface.ecomm-public-nic.id,
    azurerm_network_interface.ecomm-private-nic.id
  ]
   custom_data         = base64encode(file("ecomm.sh"))  # Base64 encode the script

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"  # Use Ubuntu 20.04
    version   = "latest"
  }

  tags = {
    Name = "ecomm-vm"
  }
}