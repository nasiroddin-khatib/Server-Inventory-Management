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

# =====================================================================
# SG
# =====================================================================

variable "alb_sg_name" {

  description = "Application Load Balancer Security Group"

  type = string

}

variable "backend_sg_name" {

  description = "Backend EC2 Security Group"

  type = string

}

variable "rds_sg_name" {

  description = "RDS Security Group"

  type = string

}

variable "jenkins_sg_name" {

  description = "Jenkins Security Group"

  type = string

}

variable "sonarqube_sg_name" {

  description = "SonarQube Security Group"

  type = string

}

variable "nexus_sg_name" {

  description = "Nexus Security Group"

  type = string

}

variable "monitoring_sg_name" {

  description = "Prometheus Grafana Security Group"

  type = string

}

# ======================================================================
# IAM ROLE
# ======================================================================

# ==========================================================
# BACKEND IAM
# ==========================================================

variable "backend_role_name" {

  description = "Backend EC2 IAM Role"

  type = string

}

variable "backend_instance_profile_name" {

  description = "Backend EC2 Instance Profile"

  type = string

}

# ==========================================================
# SECRETS MANAGER
# ==========================================================

variable "db_secret_name" {

  description = "Database Secret Name"

  type = string

}

variable "db_username" {

  description = "Database Username"

  type = string

}

variable "db_password" {

  description = "Database Password"

  type = string

  sensitive = true

}

# ==========================================================
# RDS
# ==========================================================

variable "db_instance_identifier" {

  description = "RDS Instance Identifier"

  type = string

}

variable "db_name" {

  description = "Database Name"

  type = string

}

variable "db_engine_version" {

  description = "PostgreSQL Version"

  type = string

}

variable "db_instance_class" {

  description = "RDS Instance Class"

  type = string

}

variable "db_allocated_storage" {

  description = "Allocated Storage"

  type = number

}

variable "db_storage_type" {

  description = "Storage Type"

  type = string

}

