# ===========================================================
# VPC
# ==========================================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.vpc.cidr_block
}

# ============================================================
# INTERNET GATEWAY
# ============================================================

output "internet_gateway_id" {
  description = "Ineternet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

# ===========================================================
# subnet
# ===========================================================

output "public_subnet_1_id" {

  value = aws_subnet.public_subnet_1.id

}

output "public_subnet_2_id" {

  value = aws_subnet.public_subnet_2.id

}

output "private_subnet_1_id" {

  value = aws_subnet.private_subnet_1.id

}

output "private_subnet_2_id" {

  value = aws_subnet.private_subnet_2.id

}

# ============================================================
# EIP
# ============================================================

output "nat_eip" {

  description = "Elastic IP for NAT Gateway"

  value = aws_eip.nat_eip.public_ip

}

# ==========================================================
# NAT GATEWAY
# ==========================================================

output "nat_gateway_id" {

  description = "NAT Gateway ID"

  value = aws_nat_gateway.nat_gateway.id

}

# ==========================================================
# Route table association
# ==========================================================

output "public_route_table_id" {

  description = "Public Route Table ID"

  value = aws_route_table.public_route_table.id

}

output "private_route_table_id" {

  description = "Private Route Table ID"

  value = aws_route_table.private_route_table.id

}

