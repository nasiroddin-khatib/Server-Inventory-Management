############################################
# Monitoring Security Group
############################################

resource "aws_security_group" "monitoring_sg" {

  name        = var.monitoring_sg_name
  description = "Security Group for Prometheus and Grafana"

  vpc_id = aws_vpc.main.id

  tags = {

    Name        = var.monitoring_sg_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"

  }
}


############################################
# Grafana
############################################

resource "aws_vpc_security_group_ingress_rule" "monitoring_grafana" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Grafana access"

  ip_protocol = "tcp"

  from_port = 3000
  to_port   = 3000

  cidr_ipv4 = var.admin_ip

}


############################################
# Prometheus
############################################

resource "aws_vpc_security_group_ingress_rule" "monitoring_prometheus" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Prometheus access"

  ip_protocol = "tcp"

  from_port = 9090
  to_port   = 9090

  cidr_ipv4 = var.admin_ip

}


############################################
# SSH
############################################

resource "aws_vpc_security_group_ingress_rule" "monitoring_ssh" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "SSH access"

  ip_protocol = "tcp"

  from_port = 22
  to_port   = 22

  cidr_ipv4 = var.admin_ip

}


############################################
# Outbound
############################################

resource "aws_vpc_security_group_egress_rule" "monitoring_all_outbound" {

  security_group_id = aws_security_group.monitoring_sg.id

  description = "Allow outbound traffic"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"

}
