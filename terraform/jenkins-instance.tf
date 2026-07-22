#########################################################
# Latest Amazon Linux 2023 AMI
#########################################################

data "aws_ami" "jenkins_al2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#########################################################
# Jenkins EC2 Instance
#########################################################

resource "aws_instance" "jenkins_server" {

  ami                         = data.aws_ami.jenkins_al2023.id

  instance_type               = "c7i-flex.large"

  subnet_id                   = aws_subnet.public_subnet_1.id

  vpc_security_group_ids      = [
    aws_security_group.jenkins_sg.id
  ]

  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name

  associate_public_ip_address = true

  user_data                   = file("${path.module}/jenkins-userdata.sh")

  root_block_device {

    volume_size = 50

    volume_type = "gp3"

    encrypted = true

    delete_on_termination = true
  }

  tags = {
    Name = "Jenkins-Server"
    Role = "jenkins"
  }
}
