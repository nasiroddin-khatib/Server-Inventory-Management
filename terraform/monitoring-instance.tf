###############################################
# Latest Ubuntu 24.04 LTS AMI
###############################################

data "aws_ami" "ubuntu_2404" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################
# Monitoring EC2 Instance
###############################################

resource "aws_instance" "monitoring_server" {

  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = "c7i-flex.large"
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.monitoring_instance_profile.name

  associate_public_ip_address = true

  user_data = file("${path.module}/monitoring-userdata.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "Monitoring-Server"
    Role = "monitoring"
  }
}
