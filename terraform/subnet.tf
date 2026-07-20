resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {

    Name = var.public_subnet_1_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

resource "aws_subnet" "public_subnet_2" {

  vpc_id = aws_vpc.vpc.id

  cidr_block = var.public_subnet_2_cidr

  availability_zone = var.availability_zone_2

  map_public_ip_on_launch = true

  tags = {

    Name = var.public_subnet_2_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

resource "aws_subnet" "private_subnet_1" {

  vpc_id = aws_vpc.vpc.id

  cidr_block = var.private_subnet_1_cidr

  availability_zone = var.availability_zone_1

  map_public_ip_on_launch = false

  tags = {

    Name = var.private_subnet_1_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

resource "aws_subnet" "private_subnet_2" {

  vpc_id = aws_vpc.vpc.id

  cidr_block = var.private_subnet_2_cidr

  availability_zone = var.availability_zone_2

  map_public_ip_on_launch = false

  tags = {

    Name = var.private_subnet_2_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}
