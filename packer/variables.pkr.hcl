############################################
# AWS Region
############################################

variable "aws_region" {
  description = "AWS region where Packer builds the AMI"
  type        = string
}


############################################
# Packer Build Instance Type
############################################

variable "instance_type" {
  description = "Temporary EC2 instance type used by Packer"
  type        = string
}


############################################
# Existing AWS Key Pair
############################################

variable "key_name" {
  description = "Existing EC2 key pair used by Packer"
  type        = string
}


############################################
# SSH Username
############################################

variable "ssh_username" {
  description = "SSH username for Amazon Linux 2023"
  type        = string
}


############################################
# SSH Private Key
############################################

variable "ssh_private_key_file" {
  description = "Private SSH key supplied dynamically by Jenkins"
  type        = string
  sensitive   = true
}


############################################
# Backend IAM Instance Profile
############################################

variable "backend_instance_profile_name" {
  description = "IAM instance profile attached to the temporary Packer build instance"
  type        = string
}
