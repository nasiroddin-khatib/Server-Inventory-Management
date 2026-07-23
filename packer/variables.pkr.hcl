variable "aws_region" {
  type        = string
  description = "AWS region where the AMI will be created."
}

variable "source_ami" {
  type        = string
  description = "Amazon Linux 2023 source AMI ID."
}

variable "instance_type" {
  type        = string
  description = "Temporary EC2 instance type used by Packer."
}

variable "subnet_id" {
  type        = string
  description = "Subnet where the temporary Packer build instance will be launched."
}

variable "security_group_id" {
  type        = string
  description = "Security Group attached to the temporary Packer build instance."
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM Instance Profile for the temporary Packer build instance."
}

variable "ssh_username" {
  type        = string
  description = "SSH username for Amazon Linux 2023."
  default     = "ec2-user"
}

variable "application_name" {
  type        = string
  description = "Application name."
}

variable "artifact_url" {
  type        = string
  description = "URL of the artifact stored in Nexus."
}

variable "artifact_username" {
  type        = string
  description = "Nexus username."
  sensitive   = true
}

variable "artifact_password" {
  type        = string
  description = "Nexus password."
  sensitive   = true
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix used while creating the AMI."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "owner" {
  type        = string
  description = "AMI owner tag."
}

variable "secret_name" {
  type        = string
  description = "AWS Secrets Manager secret containing Nexus credentials."
}
