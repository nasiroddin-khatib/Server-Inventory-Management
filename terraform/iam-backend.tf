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
# RDS Secrets Manager Access
#
# Allows the backend EC2 instance to retrieve the
# RDS-managed master username/password secret.
# ==========================================================

resource "aws_iam_role_policy" "backend_rds_secret_access" {

  name = "backend-rds-secret-access"

  role = aws_iam_role.backend_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Action = [

          "secretsmanager:GetSecretValue"

        ]

        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn

      }

    ]

  })

}


# ==========================================================
# Instance Profile
# ==========================================================

resource "aws_iam_instance_profile" "backend_instance_profile" {

  name = var.backend_instance_profile_name

  role = aws_iam_role.backend_role.name

}
