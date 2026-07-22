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

# ==============================================================
# SG
# ==============================================================

output "alb_sg_id" {

  value = aws_security_group.alb_sg.id

}

output "backend_sg_id" {

  value = aws_security_group.backend_sg.id

}

output "rds_sg_id" {

  value = aws_security_group.rds_sg.id

}

output "jenkins_sg_id" {

  value = aws_security_group.jenkins_sg.id

}

output "sonarqube_sg_id" {

  value = aws_security_group.sonarqube_sg.id

}

output "nexus_sg_id" {

  value = aws_security_group.nexus_sg.id

}

output "monitoring_sg_id" {

  value = aws_security_group.monitoring_sg.id

}

# ==========================================================
# BACKEND IAM
# ==========================================================

output "backend_role_name" {

  value = aws_iam_role.backend_role.name

}

output "backend_instance_profile" {

  value = aws_iam_instance_profile.backend_instance_profile.name

}

# ==========================================================
# SECRETS MANAGER
# ==========================================================

output "database_secret_arn" {

  description = "Database Secret ARN"

  value = aws_secretsmanager_secret.database_secret.arn

}

output "database_secret_name" {

  description = "Database Secret Name"

  value = aws_secretsmanager_secret.database_secret.name

}

# ==========================================================
# RDS
# ==========================================================

output "rds_endpoint" {

  description = "RDS Endpoint"

  value = aws_db_instance.postgres.endpoint

}

output "rds_database_name" {

  description = "Database Name"

  value = aws_db_instance.postgres.db_name

}

# ===========================================================
# Launch template
# ===========================================================

output "launch_template_id" {
  value = aws_launch_template.backend.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.backend.latest_version
}

output "backend_ami_id" {
  value = data.aws_ami.backend.id
}

# ================================================================
# TG 
# ================================================================

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "target_group_name" {
  value = aws_lb_target_group.backend.name
}

# ================================================================
# alb
# =================================================================

output "alb_arn" {
  value = aws_lb.backend.arn
}

output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "alb_zone_id" {
  value = aws_lb.backend.zone_id
}

# ======================================================================
# LISTENER
# =======================================================================

output "listener_arn" {
  value = aws_lb_listener.backend_http.arn
}

# ===================================================================
# ASG
# ===================================================================

output "autoscaling_group_name" {
  value = aws_autoscaling_group.backend.name
}

output "autoscaling_group_arn" {
  value = aws_autoscaling_group.backend.arn
}
