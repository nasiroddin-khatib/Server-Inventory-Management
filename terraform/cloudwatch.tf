############################################
# CPU High Alarm (Scale Out)
############################################

resource "aws_cloudwatch_metric_alarm" "cpu_high" {

  alarm_name          = "backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend.name
  }

  alarm_description = "Scale Out when CPU > 70%"

  alarm_actions = [
    aws_autoscaling_policy.scale_out.arn
  ]

  tags = {
    Name        = "backend-cpu-high"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}

############################################
# CPU Low Alarm (Scale In)
############################################

resource "aws_cloudwatch_metric_alarm" "cpu_low" {

  alarm_name          = "backend-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend.name
  }

  alarm_description = "Scale In when CPU < 30%"

  alarm_actions = [
    aws_autoscaling_policy.scale_in.arn
  ]

  tags = {
    Name        = "backend-cpu-low"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}
