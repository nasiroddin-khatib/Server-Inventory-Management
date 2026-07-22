#########################################################
# Jenkins Security Group
#########################################################

resource "aws_security_group" "jenkins_sg" {

  name        = "jenkins-security-group"

  description = "Security Group for Jenkins Server"

  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Jenkins-SG"
  }
}

#########################################################
# SSH
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {

  security_group_id = aws_security_group.jenkins_sg.id

  ip_protocol = "tcp"

  from_port = 22

  to_port = 22

  cidr_ipv4 = "152.57.226.16/32"
}

#########################################################
# Jenkins UI
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_http" {

  security_group_id = aws_security_group.jenkins_sg.id

  ip_protocol = "tcp"

  from_port = 8080

  to_port = 8080

  cidr_ipv4 = "0.0.0.0/0"
}

#########################################################
# Outbound
#########################################################

resource "aws_vpc_security_group_egress_rule" "jenkins_outbound" {

  security_group_id = aws_security_group.jenkins_sg.id

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}
