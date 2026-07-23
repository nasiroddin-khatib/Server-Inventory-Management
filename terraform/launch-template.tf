############################################
# Get Latest Backend Golden AMI
############################################

data "aws_ami" "backend" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Name"
    values = ["backend-golden-ami"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

############################################
# Launch Template
############################################

resource "aws_launch_template" "backend" {

  name_prefix   = "backend-lt-"
  image_id      = data.aws_ami.backend.id
  instance_type = var.backend_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_instance_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.backend_sg.id
  ]

  monitoring {
    enabled = true
  }

  block_device_mappings {

    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.backend_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name        = "backend-instance"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tag_specifications {

    resource_type = "volume"

    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  update_default_version = true

  lifecycle {
    create_before_destroy = true
  }

}
