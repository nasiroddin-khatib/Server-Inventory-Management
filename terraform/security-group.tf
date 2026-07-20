# =========================================================
# LOAD BALANCER SG
# =========================================================

resource "aws_security_group" "alb_sg" {

  name        = var.alb_sg_name
  description = "AWS Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {

    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Name = var.alb_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}


# ===============================================================
# BACKEND SG
# ===============================================================

resource "aws_security_group" "backend_sg" {

  name = var.backend_sg_name

  description = "Backend Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    description = "HTTP from ALB"

    from_port = 8080

    to_port = 8080

    protocol = "tcp"

    security_groups = [

      aws_security_group.alb_sg.id

    ]

  }

  ingress {

    description = "Prometheus Scraping"

    from_port = 8080

    to_port = 8080

    protocol = "tcp"

    security_groups = [

      aws_security_group.monitoring_sg.id

    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.backend_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# =====================================================================
# RDS SG 
# =====================================================================

resource "aws_security_group" "rds_sg" {

  name = var.rds_sg_name

  description = "RDS Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    description = "PostgreSQL"

    from_port = 5432

    to_port = 5432

    protocol = "tcp"

    security_groups = [

      aws_security_group.backend_sg.id

    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.rds_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# ===============================================================================
# JENKINS SG
# ===============================================================================

resource "aws_security_group" "jenkins_sg" {

  name = var.jenkins_sg_name

  description = "Jenkins Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    from_port = 8080

    to_port = 8080

    protocol = "tcp"

    cidr_blocks = ["152.57.155.252/32"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.jenkins_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# ======================================================================
# SONARQUBE SG
# ======================================================================

resource "aws_security_group" "sonarqube_sg" {

  name = var.sonarqube_sg_name

  description = "SonarQube Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    from_port = 9000

    to_port = 9000

    protocol = "tcp"

    cidr_blocks = ["152.57.155.252/32"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.sonarqube_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# ===========================================================
# NEXUS SG
# ==========================================================

resource "aws_security_group" "nexus_sg" {

  name = var.nexus_sg_name

  description = "Nexus Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    from_port = 8081

    to_port = 8081

    protocol = "tcp"

    cidr_blocks = ["152.57.155.252/32"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.nexus_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}

# =============================================================
# MONITORING SG
# =============================================================

resource "aws_security_group" "monitoring_sg" {

  name = var.monitoring_sg_name

  description = "Prometheus and Grafana Security Group"

  vpc_id = aws_vpc.vpc.id

  ingress {

    description = "Grafana"

    from_port = 3000

    to_port = 3000

    protocol = "tcp"

    cidr_blocks = ["152.57.155.252/32"]

  }

  ingress {

    description = "Prometheus"

    from_port = 9090

    to_port = 9090

    protocol = "tcp"

    cidr_blocks = ["152.57.155.252/32"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = var.monitoring_sg_name

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Terraform"

  }

}


