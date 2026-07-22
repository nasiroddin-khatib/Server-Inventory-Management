resource "aws_lb_listener" "backend_http" {

  load_balancer_arn = aws_lb.backend.arn

  port     = 80
  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.backend.arn

  }

  tags = {
    Name        = "backend-http-listener"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}
