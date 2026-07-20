# ===============================================================================
# VPC
# ===============================================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of VPC"
  type        = string
}

# ==============================================================================
# INTERNET GATEWAY
# ==============================================================================

variable "igw_name" {
  description = "Internet Gateway Name"
  type        = string
}

# =============================================================================
# SUBNETS
# =============================================================================

variable "public_subnet_1_name" {

  description = "Public Subnet 1 Name"

  type = string

}

variable "public_subnet_2_name" {

  description = "Public Subnet 2 Name"

  type = string

}

variable "private_subnet_1_name" {

  description = "Private Subnet 1 Name"

  type = string

}

variable "private_subnet_2_name" {

  description = "Private Subnet 2 Name"

  type = string

}

variable "public_subnet_1_cidr" {

  description = "Public Subnet 1 CIDR"

  type = string

}

variable "public_subnet_2_cidr" {

  description = "Public Subnet 2 CIDR"

  type = string

}

variable "private_subnet_1_cidr" {

  description = "Private Subnet 1 CIDR"

  type = string

}

variable "private_subnet_2_cidr" {

  description = "Private Subnet 2 CIDR"

  type = string

}

variable "availability_zone_1" {

  description = "Availability Zone 1"

  type = string

}

variable "availability_zone_2" {

  description = "Availability Zone 2"

  type = string

}

# =========================================================================
# ELASTIC IP
# =========================================================================

variable "eip_name" {

  description = "Elastic IP Name"

  type = string

}

# =======================================================================
# NAT GATEWAY
# =======================================================================

variable "nat_gateway_name" {

  description = "NAT Gateway Name"

  type = string


}

# =====================================================================
# RT 
# =====================================================================

variable "public_route_table_name" {

  description = "Public Route Table Name"

  type = string

}

variable "private_route_table_name" {

  description = "Private Route Table Name"

  type = string

}
