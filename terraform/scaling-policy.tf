############################################
# Scale Out Policy
############################################

resource "aws_autoscaling_policy" "scale_out" {
  count                  = var.backend_ami_id != null ? 1 : 0
  name                   = "backend-scale-out"
  autoscaling_group_name = aws_autoscaling_group.backend[0].name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = 1

  cooldown = 300

}

############################################
# Scale In Policy
############################################

resource "aws_autoscaling_policy" "scale_in" {
  count                  = var.backend_ami_id != null ? 1 : 0
  name                   = "backend-scale-in"
  autoscaling_group_name = aws_autoscaling_group.backend[0].name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = -1

  cooldown = 300

}
