
# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "terraform"
  location = "West Europe"
}

# VNet - Virtual Network
resource "azurerm_virtual_network" "tf-vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Name = "tf-vnet"
  }
}

# #public subnet
# resource "azurerm_subnet" "tf-subnet" {
#   name                 = "tf-subnet"
#   resource_group_name  = azurerm_resource_group.example.name
#   virtual_network_name = azurerm_virtu


# Public Subnet
resource "azurerm_subnet" "tf-public-subnet" {
  name                 = "tf-public-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.tf-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

# Private Subnet
resource "azurerm_subnet" "tf-private-subnet" {
  name                 = "tf-private-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.tf-vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  # tags = {
  #   Name = "tf-database-subnet"
  # }
}

# Public IP
resource "azurerm_public_ip" "tf-public-ip" {
  name                = "tf-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"

  tags = {
    Name = "tf-public-ip"
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "tf-nat-gateway" {
  name                = "tf-nat-gateway"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Standard"

  # public_ip_address_id = azurerm_public_ip.tf-public-ip.id
  depends_on = [azurerm_public_ip.tf-public-ip]

    tags = {
    Name = "tf-nat-gateway"
  }

}

resource "azurerm_subnet_nat_gateway_association" "tf-nat-gateway-association" {
  subnet_id       = azurerm_subnet.tf-private-subnet.id
  nat_gateway_id  = azurerm_nat_gateway.tf-nat-gateway.id
}

# Public Route Table
resource "azurerm_route_table" "tf-public-rt" {
  name                = "tf-public-rt"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  route {
    name                   = "internet-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = {
    Name = "tf-web-route-table"
  }
}

# Private Route Table
resource "azurerm_route_table" "tf-private-rt" {
  name                = "tf-private-rt"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Name = "tf-database-route-table"
  }
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "tf-public-rta" {
  subnet_id      = azurerm_subnet.tf-public-subnet.id
  route_table_id = azurerm_route_table.tf-public-rt.id
}

resource "azurerm_subnet_route_table_association" "tf-private-rta" {
  subnet_id      = azurerm_subnet.tf-private-subnet.id
  route_table_id = azurerm_route_table.tf-private-rt.id
}

# Network Security Groups (NSGs) and Rules
# Public NSG
resource "azurerm_network_security_group" "tf-public-nsg" {
  name                = "tf-public-nsg"
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
    Name = "tf-web-nsg"
  }
}

resource "azurerm_subnet_network_security_group_association" "tf-public-nsg-assoc" {
  subnet_id                 = azurerm_subnet.tf-public-subnet.id
  network_security_group_id = azurerm_network_security_group.tf-public-nsg.id
}

# Private NSG
resource "azurerm_network_security_group" "tf-private-nsg" {
  name                = "tf-private-nsg"
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
    Name = "tf-data-nsg"
  }
}

resource "azurerm_subnet_network_security_group_association" "tf-private-nsg-assoc" {
  subnet_id                 = azurerm_subnet.tf-private-subnet.id
  network_security_group_id = azurerm_network_security_group.tf-private-nsg.id
}

# Network Interface for Public VM
resource "azurerm_network_interface" "tf-public-nic" {
  name                = "tf-public-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf-public-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf-public-ip.id
  }
}

# Network Interface for Private VM
resource "azurerm_network_interface" "tf-private-nic" {
  name                = "tf-private-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf-private-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}