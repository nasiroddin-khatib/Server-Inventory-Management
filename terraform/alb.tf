############################################
# Backend Application Load Balancer
############################################

resource "aws_lb" "backend" {

  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  enable_deletion_protection = false

  idle_timeout = 60

  enable_http2 = true

  tags = {
    Name        = "backend-alb"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}
