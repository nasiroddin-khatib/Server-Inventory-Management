############################################
# AWS Provider
############################################

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


############################################
# Existing VPC
############################################

data "amazon-ami" "source" {
  filters = {
    name                = "al2023-ami-2023.*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }

  most_recent = true
  owners      = ["137112412989"]
}


############################################
# Existing Public Subnet
############################################

data "aws_subnet" "packer_subnet" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-1"]
  }
}


############################################
# Existing Packer Security Group
############################################

data "aws_security_group" "packer_sg" {
  filter {
    name   = "group-name"
    values = ["Server-Inventory-packer-sg"]
  }
}


############################################
# Packer AMI
############################################

source "amazon-ebs" "backend" {

  ##########################################
  # AWS
  ##########################################

  region = var.aws_region

  ##########################################
  # Source AMI
  ##########################################

  source_ami = "ami-035827357e3c7e810"

  instance_type = var.instance_type

  ##########################################
  # Existing AWS Key Pair
  ##########################################

  ssh_keypair_name = var.key_name

  ##########################################
  # Jenkins SSH Private Key
  ##########################################

  ssh_username = var.ssh_username

  ssh_private_key_file = var.ssh_private_key_file

  ##########################################
  # Existing Network
  ##########################################

  subnet_id = data.aws_subnet.packer_subnet.id

  security_group_id = data.aws_security_group.packer_sg.id

  associate_public_ip_address = true

  ##########################################
  # AMI Name
  ##########################################

  ami_name = "server-inventory-backend-{{timestamp}}"

  ##########################################
  # Root Volume
  ##########################################

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  ##########################################
  # AMI Tags
  ##########################################

  tags = {
    Name        = "server-inventory-backend-ami"
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Packer"
  }

  ##########################################
  # Skip Stop Before Create
  ##########################################

  force_deregister = true
  force_delete_snapshot = true
}


############################################
# Build
############################################

build {

  name = "server-inventory-backend"

  sources = [
    "source.amazon-ebs.backend"
  ]


  ##########################################
  # Install Java + Tomcat
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Updating Amazon Linux'",
      "echo '========================================'",

      "sudo dnf update -y",

      "echo '========================================'",
      "echo 'Installing Java 17'",
      "echo '========================================'",

      "sudo dnf install -y java-17-amazon-corretto-devel wget",

      "echo '========================================'",
      "echo 'Creating Tomcat user'",
      "echo '========================================'",

      "sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat || true",

      "echo '========================================'",
      "echo 'Downloading Tomcat 10.1.57'",
      "echo '========================================'",

      "cd /tmp",

      "wget -q https://downloads.apache.org/tomcat/tomcat-10/v10.1.57/bin/apache-tomcat-10.1.57.tar.gz",

      "echo '========================================'",
      "echo 'Installing Tomcat'",
      "echo '========================================'",

      "sudo mkdir -p /opt/tomcat",

      "sudo tar -xzf apache-tomcat-10.1.57.tar.gz -C /opt/tomcat --strip-components=1",

      "sudo chown -R tomcat:tomcat /opt/tomcat",

      "sudo chmod -R 755 /opt/tomcat",

      "echo '========================================'",
      "echo 'Creating Tomcat systemd service'",
      "echo '========================================'",

      "sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'SERVICE_EOF'\n[Unit]\nDescription=Apache Tomcat\nAfter=network.target\n\n[Service]\nType=forking\n\nUser=tomcat\nGroup=tomcat\n\nEnvironment=\"JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto\"\nEnvironment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"\nEnvironment=\"CATALINA_HOME=/opt/tomcat\"\nEnvironment=\"CATALINA_BASE=/opt/tomcat\"\nEnvironment=\"CATALINA_OPTS=-Xms512M -Xmx1024M\"\nEnvironment=\"JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom\"\n\nExecStart=/opt/tomcat/bin/startup.sh\nExecStop=/opt/tomcat/bin/shutdown.sh\n\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target\nSERVICE_EOF",

      "echo '========================================'",
      "echo 'Starting Tomcat'",
      "echo '========================================'",

      "sudo systemctl daemon-reload",

      "sudo systemctl enable tomcat",

      "sudo systemctl start tomcat",

      "sleep 10",

      "sudo systemctl is-active --quiet tomcat",

      "echo '========================================'",
      "echo 'Tomcat is running successfully'",
      "echo '========================================'"
    ]
  }


  ##########################################
  # Copy WAR from Jenkins workspace
  ##########################################

  provisioner "file" {

    source = "${path.root}/../backend/target/Server-Inventory.war"

    destination = "/tmp/Server-Inventory.war"
  }


  ##########################################
  # Deploy WAR
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Deploying Server Inventory WAR'",
      "echo '========================================'",

      "sudo systemctl stop tomcat",

      "sudo rm -rf /opt/tomcat/webapps/ROOT",

      "sudo rm -f /opt/tomcat/webapps/ROOT.war",

      "sudo rm -f /opt/tomcat/webapps/server-inventory.war",

      "sudo rm -rf /opt/tomcat/webapps/server-inventory",

      "sudo mv /tmp/Server-Inventory.war /opt/tomcat/webapps/server-inventory.war",

      "sudo chown tomcat:tomcat /opt/tomcat/webapps/server-inventory.war",

      "sudo systemctl start tomcat",

      "sleep 15",

      "sudo systemctl is-active --quiet tomcat",

      "echo '========================================'",
      "echo 'WAR deployment completed'",
      "echo '========================================'"
    ]
  }


  ##########################################
  # Verify Deployment
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Testing Tomcat'",
      "echo '========================================'",

      "curl -f http://localhost:8080/server-inventory/actuator/health",

      "echo ''",

      "echo '========================================'",
      "echo 'Backend application is healthy'",
      "echo '========================================'"
    ]
  }


  ##########################################
  # Cleanup
  ##########################################

  provisioner "shell" {

    inline = [

      "sudo rm -f /tmp/Server-Inventory.war",

      "sudo rm -f /tmp/apache-tomcat-10.1.57.tar.gz",

      "sudo dnf clean all"
    ]
  }
}
