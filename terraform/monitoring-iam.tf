############################################
# Monitoring EC2 IAM Role
############################################

resource "aws_iam_role" "monitoring" {

  name = "monitoring-ec2-role"

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
    Name        = "monitoring-ec2-role"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

}

############################################
# CloudWatch Agent Policy
############################################

resource "aws_iam_role_policy_attachment" "monitoring_cloudwatch" {

  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

}

############################################
# SSM Policy
############################################

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {

  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

############################################
# Instance Profile
############################################

resource "aws_iam_instance_profile" "monitoring" {

  name = "monitoring-instance-profile"

  role = aws_iam_role.monitoring.name

}

# ==========================================================
# ======================================================

###############################################################
# Prometheus EC2 Service Discovery Policy
###############################################################

resource "aws_iam_policy" "prometheus_ec2_discovery" {
  name        = "prometheus-ec2-discovery-policy"
  description = "Allows Prometheus to discover backend EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_ec2_discovery" {

  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.prometheus_ec2_discovery.arn

}
