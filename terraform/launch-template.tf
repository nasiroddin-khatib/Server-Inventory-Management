############################################
# Backend Launch Template
############################################

resource "aws_launch_template" "backend" {

  name_prefix   = "backend-lt-"
  image_id      = var.backend_ami_id
  instance_type = var.backend_instance_type

  key_name = "mykey"

  ############################################
  # IAM Instance Profile
  ############################################

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_instance_profile.name
  }

  ############################################
  # Security Group
  ############################################

  vpc_security_group_ids = [
    aws_security_group.backend_sg.id
  ]

  ############################################
  # Detailed Monitoring
  ############################################

  monitoring {
    enabled = true
  }

  ############################################
  # Root Volume
  ############################################

  block_device_mappings {

    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.backend_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  ############################################
  # IMDSv2
  ############################################

  metadata_options {

    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  ############################################
  # User Data
  ############################################

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -e

    echo "========================================"
    echo "Updating packages"
    echo "========================================"

    dnf update -y


    echo "========================================"
    echo "Installing Java 17 and required tools"
    echo "========================================"

    dnf install -y \
      java-17-amazon-corretto-devel \
      wget \
      tar


    echo "========================================"
    echo "Creating Tomcat user"
    echo "========================================"

    if ! id tomcat >/dev/null 2>&1; then
      useradd -r -m -U \
        -d /opt/tomcat \
        -s /bin/false \
        tomcat
    fi


    echo "========================================"
    echo "Creating Tomcat directory"
    echo "========================================"

    mkdir -p /opt/tomcat


    echo "========================================"
    echo "Downloading Apache Tomcat"
    echo "========================================"

    cd /tmp

    wget -O apache-tomcat-10.1.57.tar.gz \
      https://downloads.apache.org/tomcat/tomcat-10/v10.1.57/bin/apache-tomcat-10.1.57.tar.gz


    echo "========================================"
    echo "Extracting Tomcat"
    echo "========================================"

    tar -xzf apache-tomcat-10.1.57.tar.gz \
      -C /opt/tomcat \
      --strip-components=1


    echo "========================================"
    echo "Setting Tomcat permissions"
    echo "========================================"

    chown -R tomcat:tomcat /opt/tomcat

    chmod -R 755 /opt/tomcat


    echo "========================================"
    echo "Creating Tomcat systemd service"
    echo "========================================"

    printf '%s\n' \
      '[Unit]' \
      'Description=Apache Tomcat' \
      'After=network.target' \
      '' \
      '[Service]' \
      'Type=forking' \
      'User=tomcat' \
      'Group=tomcat' \
      'Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"' \
      'Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"' \
      'Environment="CATALINA_HOME=/opt/tomcat"' \
      'Environment="CATALINA_BASE=/opt/tomcat"' \
      'Environment="CATALINA_OPTS=-Xms512M -Xmx1024M"' \
      'Environment="JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom"' \
      'ExecStart=/opt/tomcat/bin/startup.sh' \
      'ExecStop=/opt/tomcat/bin/shutdown.sh' \
      'Restart=on-failure' \
      'RestartSec=10' \
      '' \
      '[Install]' \
      'WantedBy=multi-user.target' \
      > /etc/systemd/system/tomcat.service


    echo "========================================"
    echo "Reloading systemd"
    echo "========================================"

    systemctl daemon-reload


    echo "========================================"
    echo "Enabling Tomcat"
    echo "========================================"

    systemctl enable tomcat


    echo "========================================"
    echo "Starting Tomcat"
    echo "========================================"

    systemctl start tomcat


    echo "========================================"
    echo "Checking Tomcat status"
    echo "========================================"

    systemctl --no-pager status tomcat


    echo "========================================"
    echo "Testing Tomcat"
    echo "========================================"

    sleep 5

    if curl -f http://localhost:8080/ >/dev/null 2>&1; then
      echo "Tomcat is running successfully on port 8080"
    else
      echo "WARNING: Tomcat service started but HTTP check failed"
      systemctl --no-pager status tomcat || true
    fi


    echo "========================================"
    echo "Tomcat installation completed"
    echo "========================================"

  EOF
  )

  ############################################
  # Instance Tags
  ############################################

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name        = "backend-instance"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  ############################################
  # Volume Tags
  ############################################

  tag_specifications {

    resource_type = "volume"

    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  ############################################
  # Default Version
  ############################################

  update_default_version = true

  ############################################
  # Lifecycle
  ############################################

  lifecycle {
    create_before_destroy = true
  }

}
