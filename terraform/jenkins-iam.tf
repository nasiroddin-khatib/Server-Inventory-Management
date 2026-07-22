#########################################################
# Jenkins IAM Role
#########################################################

resource "aws_iam_role" "jenkins_role" {

  name = "jenkins-role"

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
    Name = "Jenkins-Role"
  }
}

#########################################################
# Jenkins IAM Policy
#########################################################

resource "aws_iam_policy" "jenkins_policy" {

  name        = "jenkins-policy"

  description = "Least privilege policy for Jenkins"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      #################################################
      # EC2
      #################################################

      {
        Effect = "Allow"

        Action = [
          "ec2:*"
        ]

        Resource = "*"
      },

      #################################################
      # S3
      #################################################

      {
        Effect = "Allow"

        Action = [
          "s3:*"
        ]

        Resource = "*"
      },

      #################################################
      # CloudWatch
      #################################################

      {
        Effect = "Allow"

        Action = [
          "cloudwatch:*",
          "logs:*"
        ]

        Resource = "*"
      },

      #################################################
      # Secrets Manager
      #################################################

      {
        Effect = "Allow"

        Action = [
          "secretsmanager:*"
        ]

        Resource = "*"
      },

      #################################################
      # STS
      #################################################

      {
        Effect = "Allow"

        Action = [
          "sts:GetCallerIdentity"
        ]

        Resource = "*"
      },

      #################################################
      # PassRole
      #################################################

      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "*"
      }

    ]
  })
}

#########################################################
# Attach Policy
#########################################################

resource "aws_iam_role_policy_attachment" "jenkins_policy_attachment" {

  role       = aws_iam_role.jenkins_role.name

  policy_arn = aws_iam_policy.jenkins_policy.arn
}

#########################################################
# Instance Profile
#########################################################

resource "aws_iam_instance_profile" "jenkins_instance_profile" {

  name = "jenkins-instance-profile"

  role = aws_iam_role.jenkins_role.name
}
