# ============================================================
# LOAD BALANCER SECURITY GROUP
# ============================================================

resource "aws_security_group" "alb_sg" {

  name        = var.alb_sg_name
  description = "Security Group for Application Load Balancer"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.alb_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# ALB - Allow HTTP from Internet
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http" {

  security_group_id = aws_security_group.alb_sg.id

  description = "Allow HTTP traffic from Internet"

  ip_protocol = "tcp"

  from_port = 80
  to_port   = 80

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# ALB - Allow HTTPS from Internet
# ------------------------------------------------------------


resource "aws_vpc_security_group_ingress_rule" "alb_https" {

  security_group_id = aws_security_group.alb_sg.id

  description = "Allow HTTPS traffic from Internet"

  ip_protocol = "tcp"

  from_port = 443
  to_port   = 443

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# ALB - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {

  security_group_id = aws_security_group.alb_sg.id

  description = "Allow ALB outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# BACKEND SECURITY GROUP
# ============================================================

resource "aws_security_group" "backend_sg" {

  name        = var.backend_sg_name
  description = "Security Group for Backend EC2 instances"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.backend_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# BACKEND - Allow application traffic from ALB
# ------------------------------------------------------------


resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {

  security_group_id = aws_security_group.backend_sg.id

  description = "Allow application traffic from ALB"

  ip_protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  referenced_security_group_id = aws_security_group.alb_sg.id
}


# ------------------------------------------------------------
# BACKEND - Allow Prometheus to scrape Actuator
# ------------------------------------------------------------
#


resource "aws_vpc_security_group_ingress_rule" "backend_from_monitoring" {

  security_group_id = aws_security_group.backend_sg.id

  description = "Allow Prometheus to scrape Spring Boot Actuator"

  ip_protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  referenced_security_group_id = aws_security_group.monitoring_sg.id
}


# ------------------------------------------------------------
# BACKEND - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "backend_all_outbound" {

  security_group_id = aws_security_group.backend_sg.id

  description = "Allow Backend outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# RDS SECURITY GROUP
# ============================================================

resource "aws_security_group" "rds_sg" {

  name        = var.rds_sg_name
  description = "Security Group for PostgreSQL RDS"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.rds_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# RDS - Allow PostgreSQL only from Backend
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_from_backend" {

  security_group_id = aws_security_group.rds_sg.id

  description = "Allow PostgreSQL from Backend"

  ip_protocol = "tcp"

  from_port = 5432
  to_port   = 5432

  referenced_security_group_id = aws_security_group.backend_sg.id
}


# ------------------------------------------------------------
# RDS - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {

  security_group_id = aws_security_group.rds_sg.id

  description = "Allow RDS outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# JENKINS SECURITY GROUP
# ============================================================

resource "aws_security_group" "jenkins_sg" {

  name        = var.jenkins_sg_name
  description = "Security Group for Jenkins"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.jenkins_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# JENKINS - Allow Jenkins UI from Administrator IP
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "jenkins_http" {

  security_group_id = aws_security_group.jenkins_sg.id

  description = "Allow Jenkins UI from administrator IP"

  ip_protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# JENKINS - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "jenkins_all_outbound" {

  security_group_id = aws_security_group.jenkins_sg.id

  description = "Allow Jenkins outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# SONARQUBE SECURITY GROUP
# ============================================================

resource "aws_security_group" "sonarqube_sg" {

  name        = var.sonarqube_sg_name
  description = "Security Group for SonarQube"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.sonarqube_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# SONARQUBE - Allow UI from Administrator IP
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "sonarqube_http" {

  security_group_id = aws_security_group.sonarqube_sg.id

  description = "Allow SonarQube UI from administrator IP"

  ip_protocol = "tcp"

  from_port = 9000
  to_port   = 9000

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# SONARQUBE - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "sonarqube_all_outbound" {

  security_group_id = aws_security_group.sonarqube_sg.id

  description = "Allow SonarQube outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# NEXUS SECURITY GROUP
# ============================================================

resource "aws_security_group" "nexus_sg" {

  name        = var.nexus_sg_name
  description = "Security Group for Nexus Repository"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.nexus_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# NEXUS - Allow UI from Administrator IP
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "nexus_http" {

  security_group_id = aws_security_group.nexus_sg.id

  description = "Allow Nexus UI from administrator IP"

  ip_protocol = "tcp"

  from_port = 8081
  to_port   = 8081

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# NEXUS - Allow Jenkins to access Nexus
# ------------------------------------------------------------
# Jenkins needs this if it uploads/downloads artifacts
# from Nexus on port 8081.

resource "aws_vpc_security_group_ingress_rule" "nexus_from_jenkins" {

  security_group_id = aws_security_group.nexus_sg.id

  description = "Allow Jenkins to access Nexus Repository"

  ip_protocol = "tcp"

  from_port = 8081
  to_port   = 8081

  referenced_security_group_id = aws_security_group.jenkins_sg.id
}


# ------------------------------------------------------------
# NEXUS - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "nexus_all_outbound" {

  security_group_id = aws_security_group.nexus_sg.id

  description = "Allow Nexus outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


# ============================================================
# MONITORING SECURITY GROUP
# ============================================================
# Prometheus + Grafana

resource "aws_security_group" "monitoring_sg" {

  name        = var.monitoring_sg_name
  description = "Security Group for Prometheus and Grafana"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name        = var.monitoring_sg_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}


# ------------------------------------------------------------
# MONITORING - Grafana
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "monitoring_grafana" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Allow Grafana from administrator IP"

  ip_protocol = "tcp"

  from_port = 3000
  to_port   = 3000

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# MONITORING - Prometheus
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "monitoring_prometheus" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Allow Prometheus from administrator IP"

  ip_protocol = "tcp"

  from_port = 9090
  to_port   = 9090

  cidr_ipv4 = "0.0.0.0/0"
}


# ------------------------------------------------------------
# MONITORING - Allow all outbound traffic
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "monitoring_all_outbound" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Allow Monitoring outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}
