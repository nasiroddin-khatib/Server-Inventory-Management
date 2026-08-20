############################################
# AWS Region
############################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}


############################################
# EC2 Instance Type
############################################

variable "instance_type" {
  description = "Temporary Packer build instance type"
  type        = string
}


############################################
# AWS Key Pair
############################################

variable "key_name" {
  description = "Existing EC2 key pair"
  type        = string
}


############################################
# SSH Username
############################################

variable "ssh_username" {
  description = "SSH username for Amazon Linux"
  type        = string
}


############################################
# SSH Private Key
############################################

variable "ssh_private_key_file" {
  description = "Temporary private key path supplied by Jenkins"
  type        = string
  sensitive   = true
}
