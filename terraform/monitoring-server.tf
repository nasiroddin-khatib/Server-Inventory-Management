############################################
# Ubuntu AMI
############################################

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {

    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]

  }

  filter {

    name = "virtualization-type"

    values = ["hvm"]

  }

}


############################################
# Public Subnet
############################################

data "aws_subnet" "monitoring_subnet" {

  filter {

    name = "tag:Name"

    values = ["public-subnet-1"]

  }

}


############################################
# Monitoring Server
############################################

resource "aws_instance" "monitoring" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.monitoring_instance_type

  subnet_id = data.aws_subnet.monitoring_subnet.id

  key_name = var.monitoring_key_name

  vpc_security_group_ids = [
    aws_security_group.monitoring_sg.id
  ]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  user_data = file("${path.module}/monitoring-user-data.sh")

  tags = {

    Name        = "${var.project}-monitoring"
    Project     = var.project
    Environment = var.environment
    Role        = "monitoring"
    ManagedBy   = "Terraform"

  }

}
