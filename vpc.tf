# Fetch the public IP of the machine running Terraform
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Convert to CIDR format
locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# VPC Configuration
resource "aws_vpc" "rancher_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-rancher-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "rancher_gateway" {
  vpc_id = aws_vpc.rancher_vpc.id

  tags = {
    Name = "${var.prefix}-rancher-gateway"
  }
}

# Create a Subnet
resource "aws_subnet" "rancher_subnet" {
  vpc_id            = aws_vpc.rancher_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.aws_zone

  tags = {
    Name = "${var.prefix}-rancher-subnet"
  }
}

# Create a Route Table
resource "aws_route_table" "rancher_route_table" {
  vpc_id = aws_vpc.rancher_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rancher_gateway.id
  }

  tags = {
    Name = "${var.prefix}-rancher-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "rancher_route_table_association" {
  subnet_id      = aws_subnet.rancher_subnet.id
  route_table_id = aws_route_table.rancher_route_table.id
}

# Security Group with restricted access
resource "aws_security_group" "rancher_sg_allow_my_ip" {
  name        = "${var.prefix}-rancher-allow-my-ip"
  description = "Rancher quickstart - allow traffic only from Terraform apply machine"
  vpc_id      = aws_vpc.rancher_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
    description = "Allow HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
    description = "Allow HTTPS traffic"
  }

  # Allow internal communication on HTTPS (443) between Rancher Manager and downstream clusters
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Internal VPC CIDR to allow internal communication
    description = "Allow internal HTTPS traffic within the VPC"
  }

  # Allow internal communication on HTTP (80) between Rancher Manager and downstream clusters
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Internal VPC CIDR to allow internal communication
    description = "Allow internal HTTP traffic within the VPC"
  }
  ingress {
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
    description = "Allow custom TCP traffic on port 8088"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
    description = "Allow SSH access"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
    description = "Allow custom TCP traffic on port 8000"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "${var.prefix}-quickstart"
  }
}
