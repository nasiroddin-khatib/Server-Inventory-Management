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

# ============================================================
# SUBNET
# ============================================================

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
  value       = aws_eip.nat_eip.public_ip
}

# ==========================================================
# NAT GATEWAY
# ==========================================================

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat_gateway.id
}

# ==========================================================
# Route table association
# ==========================================================

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private_route_table.id
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

# ============================================================
# RDS
# ============================================================

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_database_name" {
  description = "Database Name"
  value       = aws_db_instance.postgres.db_name
}

# ===========================================================
# Launch template
# ===========================================================

output "launch_template_id" {
  value = try(aws_launch_template.backend[0].id, null)
}

output "launch_template_latest_version" {
  value = try(aws_launch_template.backend[0].latest_version, null)
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
# ALB
# ================================================================

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
  value = try(aws_autoscaling_group.backend[0].name, null)
}

output "autoscaling_group_arn" {
  value = try(aws_autoscaling_group.backend[0].arn, null)
}

# ======================================================================
# SCALING POLICY
# ======================================================================

output "scale_out_policy_arn" {
  value = var.backend_ami_id != null ? aws_autoscaling_policy.scale_out[0].arn : null
}

output "scale_in_policy_arn" {
  value = var.backend_ami_id != null ? aws_autoscaling_policy.scale_in[0].arn : null
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

# ======================================================================
# SonarQube-Server
# ======================================================================

output "sonarqube_public_ip" {
  description = "Public IP of SonarQube server"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqube_url" {
  description = "SonarQube URL"
  value       = "http://${aws_instance.sonarqube.public_ip}:9000"
}

# ############################################
# Monitoring Server
# ############################################

output "monitoring_instance_id" {
  description = "Monitoring server instance ID"
  value       = aws_instance.monitoring.id
}

output "monitoring_public_ip" {
  description = "Monitoring server public IP"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_public_dns" {
  description = "Monitoring server public DNS"
  value       = aws_instance.monitoring.public_dns
}

output "prometheus_url" {
  description = "Prometheus web UI"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana web UI"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

# ############################################
# Nexus Server
# ############################################

output "nexus_public_ip" {
  description = "Public IP address of Nexus server"
  value       = aws_instance.nexus.public_ip
}

# ############################################
# Nexus Secret
# ############################################

output "nexus_secret_name" {
  description = "Name of the Nexus credentials secret"
  value       = data.aws_secretsmanager_secret.nexus_credentials.name
}

output "nexus_secret_arn" {
  description = "ARN of the Nexus credentials secret"
  value       = data.aws_secretsmanager_secret.nexus_credentials.arn
}
