
# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "terraform_ecomm"
  location = "West Europe"
}

# VNet - Virtual Network
resource "azurerm_virtual_network" "ecomm-vnet" {
  name                = "ecomm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Name = "ecomm-vnet"
  }
}

# #public subnet
# resource "azurerm_subnet" "ecomm-subnet" {
#   name                 = "ecomm-subnet"
#   resource_group_name  = azurerm_resource_group.example.name
#   virtual_network_name = azurerm_virtu


# Public Subnet
resource "azurerm_subnet" "ecomm-public-subnet" {
  name                 = "ecomm-public-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.ecomm-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

# Private Subnet
resource "azurerm_subnet" "ecomm-private-subnet" {
  name                 = "ecomm-private-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.ecomm-vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  # tags = {
  #   Name = "ecomm-database-subnet"
  # }
}

# Public IP
resource "azurerm_public_ip" "ecomm-public-ip" {
  name                = "ecomm-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"

  tags = {
    Name = "ecomm-public-ip"
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "ecomm-nat-gateway" {
  name                = "ecomm-nat-gateway"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Standard"

  # public_ip_address_id = azurerm_public_ip.ecomm-public-ip.id
  depends_on = [azurerm_public_ip.ecomm-public-ip]

    tags = {
    Name = "ecomm-nat-gateway"
  }

}

resource "azurerm_subnet_nat_gateway_association" "ecomm-nat-gateway-association" {
  subnet_id       = azurerm_subnet.ecomm-private-subnet.id
  nat_gateway_id  = azurerm_nat_gateway.ecomm-nat-gateway.id
}

# Public Route Table
resource "azurerm_route_table" "ecomm-public-rt" {
  name                = "ecomm-public-rt"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  route {
    name                   = "internet-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = {
    Name = "ecomm-web-route-table"
  }
}

# Private Route Table
resource "azurerm_route_table" "ecomm-private-rt" {
  name                = "ecomm-private-rt"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Name = "ecomm-database-route-table"
  }
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "ecomm-public-rta" {
  subnet_id      = azurerm_subnet.ecomm-public-subnet.id
  route_table_id = azurerm_route_table.ecomm-public-rt.id
}

resource "azurerm_subnet_route_table_association" "ecomm-private-rta" {
  subnet_id      = azurerm_subnet.ecomm-private-subnet.id
  route_table_id = azurerm_route_table.ecomm-private-rt.id
}

# Network Security Groups (NSGs) and Rules
# Public NSG
resource "azurerm_network_security_group" "ecomm-public-nsg" {
  name                = "ecomm-public-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowSSH"
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
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "ecomm-web-nsg"
  }
}

resource "azurerm_subnet_network_security_group_association" "ecomm-public-nsg-assoc" {
  subnet_id                 = azurerm_subnet.ecomm-public-subnet.id
  network_security_group_id = azurerm_network_security_group.ecomm-public-nsg.id
}

# Private NSG
resource "azurerm_network_security_group" "ecomm-private-nsg" {
  name                = "ecomm-private-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "ecomm-data-nsg"
  }
}

resource "azurerm_subnet_network_security_group_association" "ecomm-private-nsg-assoc" {
  subnet_id                 = azurerm_subnet.ecomm-private-subnet.id
  network_security_group_id = azurerm_network_security_group.ecomm-private-nsg.id
}

# Network Interface for Public VM
resource "azurerm_network_interface" "ecomm-public-nic" {
  name                = "ecomm-public-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ecomm-public-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ecomm-public-ip.id
  }
}

# Network Interface for Private VM
resource "azurerm_network_interface" "ecomm-private-nic" {
  name                = "ecomm-private-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ecomm-private-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}