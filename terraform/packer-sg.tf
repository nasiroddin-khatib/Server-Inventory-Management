############################################
# Packer Security Group
############################################

resource "aws_security_group" "packer_sg" {

  name        = "${var.project}-packer-sg"
  description = "Security group for temporary Packer build instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-packer-sg"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


############################################
# SSH Access from Jenkins Security Group
############################################

resource "aws_vpc_security_group_ingress_rule" "packer_ssh_from_jenkins" {

  security_group_id = aws_security_group.packer_sg.id

  description = "Allow SSH from Jenkins security group"

  ip_protocol = "tcp"

  from_port = 22
  to_port   = 22

  referenced_security_group_id = aws_security_group.jenkins_sg.id
}


############################################
# Outbound Internet Access
############################################

resource "aws_vpc_security_group_egress_rule" "packer_all_outbound" {

  security_group_id = aws_security_group.packer_sg.id

  description = "Allow outbound traffic for Packer build"

  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}


############################################
# Packer Security Group Output
############################################

output "packer_security_group_id" {

  description = "Security group ID used by Packer temporary instances"

  value = aws_security_group.packer_sg.id
}
