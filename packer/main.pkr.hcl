############################################
# Packer Required Plugin
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
# Latest Amazon Linux 2023 AMI
############################################

data "amazon-ami" "source" {

  filters = {
    name                = "al2023-ami-2023.*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }

  most_recent = true

  owners = [
    "137112412989"
  ]
}


############################################
# Packer AMI Source
############################################

source "amazon-ebs" "backend" {

  ##########################################
  # AWS Region
  ##########################################

  region = var.aws_region


  ##########################################
  # Source AMI
  ##########################################

  source_ami = data.amazon-ami.source.id


  ##########################################
  # Packer Build Instance Type
  ##########################################

  instance_type = var.instance_type


  ##########################################
  # AWS Key Pair
  ##########################################

  ssh_keypair_name = var.key_name


  ##########################################
  # SSH Configuration
  ##########################################

  ssh_username         = var.ssh_username
  ssh_private_key_file = var.ssh_private_key_file


  ##########################################
  # Existing Network
  ##########################################

  subnet_id = var.subnet_id

  security_group_id = var.security_group_id

  associate_public_ip_address = true


  ##########################################
  # IAM Instance Profile
  ##########################################

  iam_instance_profile = var.backend_instance_profile_name


  ##########################################
  # AMI Name
  ##########################################

  ami_name = "server-inventory-backend-{{timestamp}}"


  ##########################################
  # Root EBS Volume
  ##########################################

  launch_block_device_mappings {

    device_name = "/dev/xvda"

    volume_size = 20

    volume_type = "gp3"

    delete_on_termination = true

    encrypted = true
  }


  ##########################################
  # AMI Tags
  ##########################################

  tags = {

    Name = "server-inventory-backend-ami"

    Project = "Server-Inventory"

    Environment = "Production"

    ManagedBy = "Packer"
  }


  ##########################################
  # Cleanup Existing AMIs/Snapshots
  ##########################################

  force_deregister      = true
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
  # Install Java + Tomcat + AWS CLI + jq
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Updating Amazon Linux'",
      "echo '========================================'",

      "sudo dnf update -y",


      "echo '========================================'",
      "echo 'Installing Java 17, wget, curl, jq and AWS CLI'",
      "echo '========================================'",

      "sudo dnf install -y java-17-amazon-corretto-devel wget curl jq awscli",


      "echo '========================================'",
      "echo 'Creating Tomcat User'",
      "echo '========================================'",

      "sudo useradd --system --home /opt/tomcat --shell /sbin/nologin tomcat || true",


      "echo '========================================'",
      "echo 'Downloading Tomcat'",
      "echo '========================================'",

      "cd /tmp",

      "wget -q https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.57/bin/apache-tomcat-10.1.57.tar.gz",


      "echo '========================================'",
      "echo 'Installing Tomcat'",
      "echo '========================================'",

      "sudo mkdir -p /opt/tomcat",

      "sudo tar -xzf apache-tomcat-10.1.57.tar.gz -C /opt/tomcat --strip-components=1",

      "sudo chown -R tomcat:tomcat /opt/tomcat",

      "sudo chmod +x /opt/tomcat/bin/*.sh",


      "echo '========================================'",
      "echo 'Creating Application Configuration Directory'",
      "echo '========================================'",

      "sudo mkdir -p /etc/server-inventory",

      "sudo chown root:tomcat /etc/server-inventory",

      "sudo chmod 750 /etc/server-inventory",


      "echo '========================================'",
      "echo 'Creating Tomcat systemd Service'",
      "echo '========================================'",

      "sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'EOF'\n[Unit]\nDescription=Apache Tomcat 10.1.57\nAfter=network.target\n\n[Service]\nType=forking\nUser=tomcat\nGroup=tomcat\nEnvironment=\"JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto\"\nEnvironmentFile=/etc/server-inventory/db.env\nEnvironment=\"CATALINA_HOME=/opt/tomcat\"\nEnvironment=\"CATALINA_BASE=/opt/tomcat\"\nEnvironment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"\nEnvironment=\"CATALINA_OPTS=-Xms512M -Xmx1024M\"\nEnvironment=\"JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom\"\nExecStart=/opt/tomcat/bin/startup.sh\nExecStop=/opt/tomcat/bin/shutdown.sh\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target\nEOF",


      "echo '========================================'",
      "echo 'Retrieving RDS Secret'",
      "echo '========================================'",

      "sudo aws secretsmanager get-secret-value --secret-id '${var.rds_secret_arn}' --region '${var.aws_region}' --query SecretString --output text > /tmp/rds-secret.json",


      "echo '========================================'",
      "echo 'Creating Database Environment File'",
      "echo '========================================'",

      "RDS_HOST=$(sudo jq -r '.host' /tmp/rds-secret.json)",

      "RDS_PORT=$(sudo jq -r '.port' /tmp/rds-secret.json)",

      "RDS_DBNAME=$(sudo jq -r '.dbname' /tmp/rds-secret.json)",

      "RDS_USERNAME=$(sudo jq -r '.username' /tmp/rds-secret.json)",

      "RDS_PASSWORD=$(sudo jq -r '.password' /tmp/rds-secret.json)",


      "if [ -z \"$RDS_HOST\" ] || [ \"$RDS_HOST\" = \"null\" ]; then echo 'ERROR: RDS host is missing from secret'; exit 1; fi",

      "if [ -z \"$RDS_PORT\" ] || [ \"$RDS_PORT\" = \"null\" ]; then echo 'ERROR: RDS port is missing from secret'; exit 1; fi",

      "if [ -z \"$RDS_DBNAME\" ] || [ \"$RDS_DBNAME\" = \"null\" ]; then echo 'ERROR: RDS database name is missing from secret'; exit 1; fi",

      "if [ -z \"$RDS_USERNAME\" ] || [ \"$RDS_USERNAME\" = \"null\" ]; then echo 'ERROR: RDS username is missing from secret'; exit 1; fi",

      "if [ -z \"$RDS_PASSWORD\" ] || [ \"$RDS_PASSWORD\" = \"null\" ]; then echo 'ERROR: RDS password is missing from secret'; exit 1; fi",


      "sudo bash -c 'printf \"DB_URL=jdbc:postgresql://%s:%s/%s\\nDB_USERNAME=%s\\nDB_PASSWORD=%s\\n\" \"$RDS_HOST\" \"$RDS_PORT\" \"$RDS_DBNAME\" \"$RDS_USERNAME\" \"$RDS_PASSWORD\" > /etc/server-inventory/db.env'",

      "sudo chown root:tomcat /etc/server-inventory/db.env",

      "sudo chmod 640 /etc/server-inventory/db.env",


      "echo '========================================'",
      "echo 'Cleaning Temporary Secret'",
      "echo '========================================'",

      "sudo rm -f /tmp/rds-secret.json",


      "echo '========================================'",
      "echo 'Copying Backend WAR'",
      "echo '========================================'",

      "sudo rm -rf /opt/tomcat/webapps/server-inventory",

      "sudo rm -f /opt/tomcat/webapps/server-inventory.war"
    ]
  }


  ##########################################
  # Copy Backend WAR
  ##########################################

  provisioner "file" {

    source = "${path.root}/../backend/target/server-inventory.war"

    destination = "/tmp/server-inventory.war"
  }


  ##########################################
  # Deploy Backend WAR
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",

      "echo 'Deploying Backend WAR'",

      "echo '========================================'",

      "sudo mv /tmp/server-inventory.war /opt/tomcat/webapps/server-inventory.war",

      "sudo chown tomcat:tomcat /opt/tomcat/webapps/server-inventory.war",

      "sudo chmod 644 /opt/tomcat/webapps/server-inventory.war",


      "echo '========================================'",

      "echo 'Starting Tomcat'",

      "echo '========================================'",

      "sudo systemctl daemon-reload",

      "sudo systemctl enable tomcat",

      "sudo systemctl start tomcat",


      "echo '========================================'",

      "echo 'Waiting for Tomcat'",

      "echo '========================================'",

      "sleep 15",


      "echo '========================================'",

      "echo 'Tomcat Status'",

      "echo '========================================'",

      "sudo systemctl status tomcat --no-pager || true",


      "echo '========================================'",

      "echo 'Deployed Applications'",

      "echo '========================================'",

      "sudo ls -lah /opt/tomcat/webapps/",

      "sudo ls -lah /opt/tomcat/webapps/server-inventory/ || true"
    ]
  }


  ##########################################
  # Application Health Check
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",

      "echo 'Checking Application Health'",

      "echo '========================================'",


      "for i in $(seq 1 30); do",

      "  echo \"Health check attempt $i/30\";",

      "  if curl -fsS http://127.0.0.1:8080/server-inventory/actuator/health; then",

      "    echo '';",

      "    echo '========================================';",

      "    echo 'APPLICATION HEALTH CHECK PASSED';",

      "    echo '========================================';",

      "    exit 0;",

      "  fi;",

      "  sleep 5;",

      "done",


      "echo '========================================'",

      "echo 'APPLICATION HEALTH CHECK FAILED'",

      "echo '========================================'",


      "echo 'Tomcat status:'",

      "sudo systemctl status tomcat --no-pager || true",


      "echo 'Listening on port 8080:'",

      "sudo ss -lntp | grep 8080 || true",


      "echo 'Webapps:'",

      "sudo ls -lah /opt/tomcat/webapps/ || true",


      "echo 'Application directory:'",

      "sudo ls -lah /opt/tomcat/webapps/server-inventory/ || true",


      "echo 'Root endpoint:'",

      "curl -i http://127.0.0.1:8080/ || true",


      "echo 'Application context:'",

      "curl -i http://127.0.0.1:8080/server-inventory/ || true",


      "echo 'Actuator endpoint:'",

      "curl -i http://127.0.0.1:8080/server-inventory/actuator/ || true",


      "echo 'Health endpoint:'",

      "curl -i http://127.0.0.1:8080/server-inventory/actuator/health || true",


      "echo 'Recent Tomcat logs:'",

      "sudo journalctl -u tomcat --no-pager -n 100 || true",


      "echo 'Catalina log:'",

      "sudo tail -n 100 /opt/tomcat/logs/catalina.out || true",


      "exit 1"
    ]
  }


  ##########################################
  # Remove Database Secret Before AMI
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",

      "echo 'Removing Database Secret Before AMI Creation'",

      "echo '========================================'",

      "sudo systemctl stop tomcat",

      "sudo rm -f /etc/server-inventory/db.env",

      "echo 'Database credentials removed from AMI build instance.'"
    ]
  }


  ##########################################
  # CloudWatch Agent
  ##########################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",

      "echo 'Installing CloudWatch Agent'",

      "echo '========================================'",

      "cd /tmp",

      "wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",

      "sudo rpm -U ./amazon-cloudwatch-agent.rpm || true",

      "rm -f amazon-cloudwatch-agent.rpm"
    ]
  }


  ##########################################
  # Final Cleanup
  ##########################################

  provisioner "shell" {

    inline = [

      "echo '========================================'",

      "echo 'Final Cleanup'",

      "echo '========================================'",

      "sudo rm -f /tmp/rds-secret.json",

      "sudo rm -f /tmp/apache-tomcat-10.1.57.tar.gz",

      "sudo rm -f /tmp/server-inventory.war",

      "sudo dnf clean all || true"
    ]
  }


  ##########################################
  # Manifest
  ##########################################

  post-processor "manifest" {

    output = "manifest.json"

    strip_path = true
  }
}
