resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {

    Name        = var.nat_gateway_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

  depends_on = [

    aws_internet_gateway.igw

  ]
}

