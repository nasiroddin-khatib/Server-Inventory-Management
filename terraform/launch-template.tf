############################################
# Backend Launch Template
############################################

resource "aws_launch_template" "backend" {

  name_prefix   = "backend-lt-"
  image_id      = var.backend_ami_id
  instance_type = var.backend_instance_type

  key_name = "mykey"

  ############################################
  # IAM Instance Profile
  ############################################

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_instance_profile.name
  }

  ############################################
  # Security Group
  ############################################

  vpc_security_group_ids = [
    aws_security_group.backend_sg.id
  ]

  ############################################
  # Detailed Monitoring
  ############################################

  monitoring {
    enabled = true
  }

  ############################################
  # Root Volume
  ############################################

  block_device_mappings {

    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.backend_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  ############################################
  # IMDSv2
  ############################################

  metadata_options {

    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }




  ############################################
  # Instance Tags
  ############################################

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name        = "backend-instance"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Role        = "backend"
    }
  }

  ############################################
  # Volume Tags
  ############################################

  tag_specifications {

    resource_type = "volume"

    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  ############################################
  # Default Version
  ############################################

  update_default_version = true

  ############################################
  # Lifecycle
  ############################################

  lifecycle {
    create_before_destroy = true
  }

}
