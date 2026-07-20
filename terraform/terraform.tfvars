# ========================================================
# VPC
# ========================================================

aws_region = "ap-south-1"
vpc_name   = "vpc"
vpc_cidr   = "10.0.0.0/16"

# =========================================================
# INTERNET GATEWAY
# =========================================================

igw_name = "igw"

# =========================================================
# SUBNET
# =========================================================

public_subnet_1_name = "public-subnet-1"

public_subnet_2_name = "public-subnet-2"

private_subnet_1_name = "private-subnet-1"

private_subnet_2_name = "private-subnet-2"

public_subnet_1_cidr = "10.0.1.0/24"

public_subnet_2_cidr = "10.0.2.0/24"

private_subnet_1_cidr = "10.0.3.0/24"

private_subnet_2_cidr = "10.0.4.0/24"

availability_zone_1 = "ap-south-1a"

availability_zone_2 = "ap-south-1b"

# ===========================================================
# EIP
# ===========================================================

eip_name = "nat-eip"

# ===========================================================
# NAT GATEWAY
# ===========================================================

nat_gateway_name = "nat-gateway"

# ===========================================================
# ROUTE TABLE
# ===========================================================

public_route_table_name = "public-route-table"

private_route_table_name = "private-route-table"

# ==========================================================
# SG
# ==========================================================

alb_sg_name = "alb-sg"

backend_sg_name = "backend-sg"

rds_sg_name = "rds-sg"

jenkins_sg_name = "jenkins-sg"

sonarqube_sg_name = "sonarqube-sg"

nexus_sg_name = "nexus-sg"

monitoring_sg_name = "monitoring-sg"

# =========================================================
# IAM ROLE
# =========================================================

# ==========================================================
# BACKEND IAM
# ==========================================================

backend_role_name = "backend-role"

backend_instance_profile_name = "backend-instance-profile"
