resource "aws_route_table" "public_route_table" {

  vpc_id = aws_vpc.vpc.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {

    Name        = var.public_route_table_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

}


# ==========================
# Private Route Table
# ==========================

resource "aws_route_table" "private_route_table" {

  vpc_id = aws_vpc.vpc.id

  route {

    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {

    Name        = var.private_route_table_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

}

# ==========================
# Public Subnet 1 Association
# ==========================

resource "aws_route_table_association" "public_subnet_1" {

  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id

}

# ==========================
# Public Subnet 2 Association
# ==========================

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# ==========================
# Private Subnet 1 Association
# ==========================

resource "aws_route_table_association" "private_subnet_1" {

  subnet_id = aws_subnet.private_subnet_1.id

  route_table_id = aws_route_table.private_route_table.id

}

# ==========================
# Private Subnet 2 Association
# ==========================

resource "aws_route_table_association" "private_subnet_2" {

  subnet_id = aws_subnet.private_subnet_2.id

  route_table_id = aws_route_table.private_route_table.id

}
