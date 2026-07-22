packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

source "amazon-ebs" "monitoring" {

  region        = var.aws_region
  instance_type = var.instance_type

  ssh_username = "ubuntu"

  ami_name = "monitoring-golden-ami-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

  source_ami_filter {

    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  tags = {
    Name        = "monitoring-golden-ami"
    Project     = "ServerInventory"
    Environment = "Production"
    ManagedBy   = "Packer"
  }

}

build {

  name = "monitoring"

  sources = [
    "source.amazon-ebs.monitoring"
  ]

  shell {
    script = "install.sh"
  }

}
