############################################
# Scale Out Policy
############################################

resource "aws_autoscaling_policy" "scale_out" {

  name                   = "backend-scale-out"
  autoscaling_group_name = aws_autoscaling_group.backend.name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = 1

  cooldown = 300

}

############################################
# Scale In Policy
############################################

resource "aws_autoscaling_policy" "scale_in" {

  name                   = "backend-scale-in"
  autoscaling_group_name = aws_autoscaling_group.backend.name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = -1

  cooldown = 300

}
