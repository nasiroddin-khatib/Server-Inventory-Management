# ============================================================
# Jenkins EC2 IAM Role - SSM Access
# ============================================================

resource "aws_iam_role" "jenkins_role" {
  name = "server-inventory-jenkins-role"

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
    Name      = "server-inventory-jenkins-role"
    Project   = "Server-Inventory"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# Allow Jenkins EC2 to be managed through AWS Systems Manager
# ============================================================

resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# EC2 Instance Profile
# ============================================================

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "server-inventory-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}


# ============================================================
# Jenkins EC2 Instance
# ============================================================

resource "aws_instance" "jenkins" {
  ami           = "ami-0ac7b260cf76d8865"
  instance_type = "c7i-flex.large"

  subnet_id = aws_subnet.public_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id
  ]

  associate_public_ip_address = true

  key_name = "mykey"

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  # ==========================================================
  # Root Volume - 20 GB
  # ==========================================================

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # ==========================================================
  # Jenkins Server Bootstrap
  # ==========================================================

  user_data = <<-EOF
#!/bin/bash

set -e

# --------------------------------------------------------
# Update packages
# --------------------------------------------------------

dnf update -y

# --------------------------------------------------------
# Install Git and Docker
# --------------------------------------------------------

dnf install -y git docker

# --------------------------------------------------------
# Start Docker
# --------------------------------------------------------

systemctl enable --now docker

# --------------------------------------------------------
# Start SSM Agent
# Amazon Linux 2023 normally includes the agent
# --------------------------------------------------------

systemctl enable --now amazon-ssm-agent

# --------------------------------------------------------
# Clone Server Inventory repository
# --------------------------------------------------------

cd /opt

git clone https://github.com/nasiroddin-khatib/Server-Inventory-Management.git

# --------------------------------------------------------
# Go to project directory
# --------------------------------------------------------

cd /opt/Server-Inventory-Management

# --------------------------------------------------------
# Build custom Jenkins image
# Jenkins plugins are installed during image build
# --------------------------------------------------------

docker build -t custom-jenkins:latest .

# --------------------------------------------------------
# Create Jenkins container
# --------------------------------------------------------

docker run -d \
  --name custom-jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -u root \
  custom-jenkins:latest

EOF

  tags = {
    Name        = "Server-Inventory-Jenkins"
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
