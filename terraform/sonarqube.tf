# ============================================================
# SonarQube EC2 IAM Role
# Used for AWS Systems Manager - SSH-less management
# ============================================================

resource "aws_iam_role" "sonarqube_role" {
  name = "server-inventory-sonarqube-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "server-inventory-sonarqube-role"
    Project   = "Server-Inventory"
    ManagedBy = "Terraform"
  }
}

# =======================================================================
# =======================================================================

resource "aws_iam_role_policy" "sonarqube_secrets_access" {
  name = "sonarqube-secrets-access"
  role = aws_iam_role.sonarqube_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.sonarqube_database.arn
      }
    ]
  })
}


# ============================================================
# SSM Permission
# ============================================================

resource "aws_iam_role_policy_attachment" "sonarqube_ssm" {
  role       = aws_iam_role.sonarqube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# Instance Profile
# ============================================================

resource "aws_iam_instance_profile" "sonarqube_profile" {
  name = "server-inventory-sonarqube-profile"
  role = aws_iam_role.sonarqube_role.name
}


# ============================================================
# SonarQube EC2 Instance
# ============================================================

resource "aws_instance" "sonarqube" {

  ami           = "ami-006f82a1d5a27da54"
  instance_type = "c7i-flex.large"

  # Existing Terraform public subnet
  subnet_id = aws_subnet.public_subnet_1.id

  # Existing SonarQube Security Group
  vpc_security_group_ids = [
    aws_security_group.sonarqube_sg.id
  ]

  # Enable public IP
  associate_public_ip_address = true

  # Existing key pair
  key_name = "mykey"

  # SSM access
  iam_instance_profile = aws_iam_instance_profile.sonarqube_profile.name


  # ==========================================================
  # Root Volume
  # ==========================================================

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }


  # ==========================================================
  # SonarQube Installation
  # ==========================================================

  user_data = <<-EOT
    #!/bin/bash

    set -e

    SONAR_VERSION="10.5.1.90531"
    SONAR_ZIP="sonarqube-$${SONAR_VERSION}.zip"
    SONAR_URL="https://binaries.sonarsource.com/Distribution/sonarqube/$${SONAR_ZIP}"


    echo "==============================="
    echo "Updating Packages"
    echo "==============================="

    apt update -y


    echo "==============================="
    echo "Installing Java"
    echo "==============================="

    apt install -y openjdk-17-jdk wget unzip curl

    java -version


    echo "==============================="
    echo "Installing PostgreSQL"
    echo "==============================="

    apt install -y postgresql postgresql-contrib

    systemctl enable postgresql
    systemctl start postgresql


    echo "==============================="
    echo "Creating Database"
    echo "==============================="

    sudo -u postgres psql <<EOF

    DROP DATABASE IF EXISTS sonarqube;
    DROP ROLE IF EXISTS sonar;

    CREATE ROLE sonar LOGIN PASSWORD 'sonar123';
    CREATE DATABASE sonarqube OWNER sonar;

    \c sonarqube

    ALTER SCHEMA public OWNER TO sonar;

    GRANT ALL ON SCHEMA public TO sonar;

    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES TO sonar;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO sonar;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON FUNCTIONS TO sonar;

    EOF


    echo "==============================="
    echo "Creating Sonar User"
    echo "==============================="

    if ! id sonar >/dev/null 2>&1; then
        useradd -r -m -d /opt/sonarqube -s /bin/bash sonar
    fi


    echo "==============================="
    echo "Removing Old Installation"
    echo "==============================="

    rm -rf /opt/sonarqube


    echo "==============================="
    echo "Downloading SonarQube"
    echo "==============================="

    cd /tmp

    wget -O "$${SONAR_ZIP}" "$${SONAR_URL}"


    echo "==============================="
    echo "Extracting SonarQube"
    echo "==============================="

    unzip -q "$${SONAR_ZIP}" -d /opt

    mv "/opt/sonarqube-$${SONAR_VERSION}" /opt/sonarqube

    chown -R sonar:sonar /opt/sonarqube


    echo "==============================="
    echo "Configuring SonarQube"
    echo "==============================="

    cat >> /opt/sonarqube/conf/sonar.properties <<EOF

    sonar.jdbc.username=sonar
    sonar.jdbc.password=sonar123
    sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

    EOF


    echo "==============================="
    echo "Kernel Configuration"
    echo "==============================="

    echo "vm.max_map_count=524288" > /etc/sysctl.d/99-sonarqube.conf
    echo "fs.file-max=131072" >> /etc/sysctl.d/99-sonarqube.conf

    sysctl --system


    echo "==============================="
    echo "Limits Configuration"
    echo "==============================="

    cat > /etc/security/limits.d/99-sonarqube.conf <<EOF

    sonar soft nofile 131072
    sonar hard nofile 131072
    sonar soft nproc 8192
    sonar hard nproc 8192

    EOF


    echo "==============================="
    echo "Creating SonarQube Service"
    echo "==============================="

    cat > /etc/systemd/system/sonarqube.service <<EOF

    [Unit]
    Description=SonarQube
    After=network.target postgresql.service

    [Service]
    Type=forking

    User=sonar
    Group=sonar

    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

    Restart=always
    RestartSec=10

    LimitNOFILE=131072
    LimitNPROC=8192

    [Install]
    WantedBy=multi-user.target

    EOF


    echo "==============================="
    echo "Reloading Systemd"
    echo "==============================="

    systemctl daemon-reload

    systemctl enable sonarqube


    echo "==============================="
    echo "Starting SonarQube"
    echo "==============================="

    systemctl restart sonarqube


    echo "==============================="
    echo "Waiting for SonarQube"
    echo "==============================="

    sleep 15


    echo "==============================="
    echo "Service Status"
    echo "==============================="

    systemctl status sonarqube --no-pager

  EOT


  # ==========================================================
  # Tags
  # ==========================================================

  tags = {
    Name        = "Server-Inventory-Sonarqube"
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
