############################################
# Monitoring IAM Role
############################################

resource "aws_iam_role" "monitoring" {

  name = "${var.project}-monitoring-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]

  })

  tags = {

    Name        = "${var.project}-monitoring-role"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"

  }
}


############################################
# Monitoring IAM Policy
############################################

resource "aws_iam_role_policy" "monitoring" {

  name = "${var.project}-monitoring-policy"

  role = aws_iam_role.monitoring.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances"
        ]

        Resource = "*"
      }

    ]

  })
}


############################################
# Instance Profile
############################################

resource "aws_iam_instance_profile" "monitoring" {

  name = "${var.project}-monitoring-profile"

  role = aws_iam_role.monitoring.name

}
