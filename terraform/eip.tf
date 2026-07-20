resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {

    Name        = var.eip_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

}
