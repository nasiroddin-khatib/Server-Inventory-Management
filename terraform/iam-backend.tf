# ==========================================================
# Backend IAM Role
# ==========================================================

resource "aws_iam_role" "backend_role" {

  name = var.backend_role_name

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

    Name        = var.backend_role_name
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }

}

# ==========================================================
# SSM
# ==========================================================

resource "aws_iam_role_policy_attachment" "backend_ssm" {

  role = aws_iam_role.backend_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

# ==========================================================
# CloudWatch Agent
# ==========================================================

resource "aws_iam_role_policy_attachment" "backend_cloudwatch" {

  role = aws_iam_role.backend_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

}

# ==========================================================
# Instance Profile
# ==========================================================

resource "aws_iam_instance_profile" "backend_instance_profile" {

  name = var.backend_instance_profile_name

  role = aws_iam_role.backend_role.name

}
