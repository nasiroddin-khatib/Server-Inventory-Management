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
      "echo 'Installing Java 17, wget and curl'",
      "echo '========================================'",

      "sudo dnf install -y java-17-amazon-corretto-devel wget curl",


      "echo '========================================'",
      "echo 'Creating Tomcat User'",
      "echo '========================================'",

      "sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat || true",


      "echo '========================================'",
      "echo 'Downloading Tomcat 10.1.57'",
      "echo '========================================'",

      "cd /tmp",

      "wget -q -f -O apache-tomcat-10.1.57.tar.gz https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.57/bin/apache-tomcat-10.1.57.tar.gz",


      "echo '========================================'",
      "echo 'Installing Tomcat'",
      "echo '========================================'",

      "sudo mkdir -p /opt/tomcat",

      "sudo tar -xzf /tmp/apache-tomcat-10.1.57.tar.gz -C /opt/tomcat --strip-components=1",

      "sudo chown -R tomcat:tomcat /opt/tomcat",

      "sudo chmod -R 755 /opt/tomcat",


      "echo '========================================'",
      "echo 'Creating Tomcat Systemd Service'",
      "echo '========================================'",

      "sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'SERVICE_EOF'\n[Unit]\nDescription=Apache Tomcat\nAfter=network.target\n\n[Service]\nType=forking\nUser=tomcat\nGroup=tomcat\nEnvironment=\"JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto\"\nEnvironment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"\nEnvironment=\"CATALINA_HOME=/opt/tomcat\"\nEnvironment=\"CATALINA_BASE=/opt/tomcat\"\nEnvironment=\"CATALINA_OPTS=-Xms512M -Xmx1024M\"\nEnvironment=\"JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom\"\nExecStart=/opt/tomcat/bin/startup.sh\nExecStop=/opt/tomcat/bin/shutdown.sh\nRestart=on-failure\nRestartSec=10\nLimitNOFILE=65536\n\n[Install]\nWantedBy=multi-user.target\nSERVICE_EOF",


      "echo '========================================'",
      "echo 'Starting Tomcat'",
      "echo '========================================'",

      "sudo systemctl daemon-reload",

      "sudo systemctl enable tomcat",

      "sudo systemctl start tomcat",

      "sleep 10",

      "sudo systemctl is-active --quiet tomcat",

      "echo 'Tomcat is running successfully'"

    ]
  }


  ############################################
  # Copy WAR from Jenkins Workspace
  ############################################

  provisioner "file" {

    source = "${path.root}/../backend/target/server-inventory.war"

    destination = "/tmp/server-inventory.war"
  }


  ############################################
  # Deploy WAR
  ############################################

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

      "sudo mv /tmp/server-inventory.war /opt/tomcat/webapps/server-inventory.war",

      "sudo chown tomcat:tomcat /opt/tomcat/webapps/server-inventory.war",

      "sudo systemctl start tomcat",

      "sleep 15",

      "sudo systemctl is-active --quiet tomcat",

      "echo 'WAR deployment completed'"

    ]
  }


  ############################################
  # Verify Application
  ############################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Testing Backend Application'",
      "echo '========================================'",

      "curl -f http://localhost:8080/server-inventory/actuator/health",

      "echo ''",

      "echo '========================================'",
      "echo 'Backend application is healthy'",
      "echo '========================================'"

    ]
  }


  ############################################
  # Install CloudWatch Agent
  ############################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Installing Amazon CloudWatch Agent'",
      "echo '========================================'",

      "sudo dnf install -y wget",

      "wget -q -O /tmp/amazon-cloudwatch-agent.rpm https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",

      "sudo rpm -U /tmp/amazon-cloudwatch-agent.rpm",

      "rm -f /tmp/amazon-cloudwatch-agent.rpm",

      "echo 'CloudWatch Agent installed successfully'"

    ]
  }


  ############################################
  # CloudWatch Agent Configuration
  ############################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Creating CloudWatch Agent Configuration'",
      "echo '========================================'",

      "sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",

      "sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<'CW_EOF'\n{\n  \"agent\": {\n    \"metrics_collection_interval\": 60,\n    \"run_as_user\": \"root\"\n  },\n  \"logs\": {\n    \"logs_collected\": {\n      \"files\": {\n        \"collect_list\": [\n          {\n            \"file_path\": \"/var/log/messages\",\n            \"log_group_name\": \"/server-inventory/system/messages\",\n            \"log_stream_name\": \"{instance_id}\",\n            \"retention_in_days\": 14\n          },\n          {\n            \"file_path\": \"/var/log/secure\",\n            \"log_group_name\": \"/server-inventory/system/secure\",\n            \"log_stream_name\": \"{instance_id}\",\n            \"retention_in_days\": 14\n          },\n          {\n            \"file_path\": \"/opt/tomcat/logs/catalina.out\",\n            \"log_group_name\": \"/server-inventory/application/tomcat\",\n            \"log_stream_name\": \"{instance_id}\",\n            \"retention_in_days\": 14\n          }\n        ]\n      }\n    }\n  },\n  \"metrics\": {\n    \"namespace\": \"ServerInventory/EC2\",\n    \"append_dimensions\": {\n      \"InstanceId\": \"$${aws:InstanceId}\",\n      \"InstanceType\": \"$${aws:InstanceType}\",\n      \"AutoScalingGroupName\": \"$${aws:AutoScalingGroupName}\"\n    },\n    \"metrics_collected\": {\n      \"cpu\": {\n        \"measurement\": [\n          \"cpu_usage_idle\",\n          \"cpu_usage_user\",\n          \"cpu_usage_system\"\n        ],\n        \"metrics_collection_interval\": 60,\n        \"resources\": [\n          \"*\"\n        ],\n        \"totalcpu\": true\n      },\n      \"disk\": {\n        \"measurement\": [\n          \"used_percent\"\n        ],\n        \"metrics_collection_interval\": 60,\n        \"resources\": [\n          \"*\"\n        ]\n      },\n      \"diskio\": {\n        \"measurement\": [\n          \"read_bytes\",\n          \"write_bytes\"\n        ],\n        \"metrics_collection_interval\": 60,\n        \"resources\": [\n          \"*\"\n        ]\n      },\n      \"mem\": {\n        \"measurement\": [\n          \"mem_used_percent\"\n        ],\n        \"metrics_collection_interval\": 60\n      },\n      \"swap\": {\n        \"measurement\": [\n          \"swap_used_percent\"\n        ],\n        \"metrics_collection_interval\": 60\n      }\n    }\n  }\n}\nCW_EOF",

      "sudo chown root:root /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",

      "sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json",

      "echo 'CloudWatch Agent configuration created'"

    ]
  }


  ############################################
  # Start CloudWatch Agent
  ############################################

  provisioner "shell" {

    inline = [

      "set -e",

      "echo '========================================'",
      "echo 'Starting CloudWatch Agent'",
      "echo '========================================'",

      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",

      "sudo systemctl enable amazon-cloudwatch-agent",

      "sudo systemctl is-active --quiet amazon-cloudwatch-agent",

      "echo 'CloudWatch Agent is running successfully'"

    ]
  }


  ############################################
  # Cleanup
  ############################################

  provisioner "shell" {

    inline = [

      "sudo rm -f /tmp/server-inventory.war",

      "sudo rm -f /tmp/apache-tomcat-10.1.57.tar.gz",

      "sudo dnf clean all"

    ]
  }


  ############################################
  # Generate AMI Manifest
  ############################################

  post-processor "manifest" {

    output = "packer-manifest.json"

    strip_path = true

  }

}
