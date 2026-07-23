packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3.9"
    }
  }
}

source "amazon-ebs" "backend" {

  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username

  subnet_id            = var.subnet_id
  security_group_id    = var.security_group_id
  iam_instance_profile = var.iam_instance_profile

  associate_public_ip_address              = true
  temporary_security_group_source_public_ip = true

  source_ami_filter {

    filters = {

      name                = "al2023-ami-2023*-x86_64"

      root-device-type    = "ebs"

      virtualization-type = "hvm"

    }

    most_recent = true

    owners = ["amazon"]

  }

  ami_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"

  ami_description = "Golden Backend AMI for ${var.application_name}"

  encrypt_boot = true

  launch_block_device_mappings {

    device_name = "/dev/xvda"

    volume_size = 20

    volume_type = "gp3"

    delete_on_termination = true

    encrypted = true

  }

  tags = {

    Name = var.ami_name_prefix

    Project = var.application_name

    Environment = var.environment

    Owner = var.owner

    ManagedBy = "Packer"

    Purpose = "Backend Golden AMI"

  }

  snapshot_tags = {

    Name = var.ami_name_prefix

    Project = var.application_name

    Environment = var.environment

    ManagedBy = "Packer"

  }

  run_tags = {

    Name = "packer-build-instance"

    ManagedBy = "Packer"

    Project = var.application_name

  }

}

build {

  name = "backend-golden-ami"

  sources = [
    "source.amazon-ebs.backend"
  ]

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    environment_vars = [

      "AWS_REGION=${var.aws_region}",

      "APPLICATION_NAME=${var.application_name}",

      "SECRET_NAME=${var.secret_name}",

      "ENVIRONMENT=${var.environment}"

    ]

    script = "scripts/01-install-java.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/02-install-tomcat.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/03-configure-tomcat.sh"

  }

  provisioner "file" {

    source = "files/cloudwatch-config.json"

    destination = "/tmp/cloudwatch-config.json"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/04-install-cloudwatch-agent.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/05-configure-cloudwatch-agent.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    environment_vars = [

      "AWS_REGION=${var.aws_region}",

      "SECRET_NAME=${var.secret_name}",

      "APPLICATION_NAME=${var.application_name}"

    ]

    script = "scripts/06-download-artifact.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/07-deploy-application.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/08-cleanup.sh"

  }

  provisioner "shell" {

    execute_command = "sudo -E bash '{{ .Path }}'"

    script = "scripts/09-validate.sh"

  }

}
