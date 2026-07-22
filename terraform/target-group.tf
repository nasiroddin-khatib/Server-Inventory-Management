############################################
# Backend Target Group
############################################

resource "aws_lb_target_group" "backend" {

  name        = "backend-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = aws_vpc.vpc.id

  health_check {

    enabled = true

    protocol = "HTTP"

    path = "/server-inventory/actuator/health"

    port = "traffic-port"

    matcher = "200"

    interval = 30

    timeout = 5

    healthy_threshold = 2

    unhealthy_threshold = 3
  }

  tags = {
    Name        = "backend-target-group"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}
