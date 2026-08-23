# ============================================================
# SonarQube EC2 IAM Role
# Used for AWS Systems Manager + Secrets Manager
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


# ============================================================
# Allow SonarQube EC2 to read ONLY its database secret
# ============================================================

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

        Resource = data.aws_secretsmanager_secret.sonarqube_database.arn
      }
    ]
  })
}


# ============================================================
# AWS Systems Manager Permission
# Allows SSH-less EC2 management
# ============================================================

resource "aws_iam_role_policy_attachment" "sonarqube_ssm" {
  role       = aws_iam_role.sonarqube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# EC2 Instance Profile
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

  # Existing public subnet
  subnet_id = aws_subnet.public_subnet_1.id

  # Existing SonarQube security group
  vpc_security_group_ids = [
    aws_security_group.sonarqube_sg.id
  ]

  # Assign public IP
  associate_public_ip_address = true

  # Existing key pair
  key_name = "mykey"

  # Attach IAM role
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
  # SonarQube User Data
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
echo "Installing Java, AWS CLI and Tools"
echo "==============================="

apt install -y openjdk-17-jdk wget unzip curl jq

java -version

echo "==============================="
echo "Installing AWS CLI v2"
echo "==============================="

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "/tmp/awscliv2.zip"

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

rm -rf /tmp/aws /tmp/awscliv2.zip

aws --version


echo "==============================="
echo "Installing PostgreSQL"
echo "==============================="

apt install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql


echo "==============================="
echo "Retrieving Database Credentials"
echo "==============================="

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id server-inventory/sonarqube/database \
  --query SecretString \
  --output text)

SONAR_DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
SONAR_DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')


echo "Secret retrieved successfully."


echo "==============================="
echo "Creating PostgreSQL Database"
echo "==============================="

sudo -u postgres psql <<EOF

DROP DATABASE IF EXISTS sonarqube;
DROP ROLE IF EXISTS $SONAR_DB_USER;

CREATE ROLE $SONAR_DB_USER LOGIN PASSWORD '$SONAR_DB_PASSWORD';

CREATE DATABASE sonarqube OWNER $SONAR_DB_USER;

\c sonarqube

ALTER SCHEMA public OWNER TO $SONAR_DB_USER;

GRANT ALL ON SCHEMA public TO $SONAR_DB_USER;

GRANT ALL PRIVILEGES ON DATABASE sonarqube TO $SONAR_DB_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO $SONAR_DB_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO $SONAR_DB_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON FUNCTIONS TO $SONAR_DB_USER;

EOF


echo "==============================="
echo "Creating SonarQube Linux User"
echo "==============================="

if ! id sonar >/dev/null 2>&1; then
    useradd -r -m -d /opt/sonarqube -s /bin/bash sonar
fi


echo "==============================="
echo "Removing Old SonarQube Installation"
echo "==============================="

rm -rf /opt/sonarqube


echo "==============================="
echo "Downloading SonarQube"
echo "==============================="

cd /tmp

wget -O "$SONAR_ZIP" "$SONAR_URL"


echo "==============================="
echo "Extracting SonarQube"
echo "==============================="

unzip -q "$SONAR_ZIP" -d /opt

mv "/opt/sonarqube-$SONAR_VERSION" /opt/sonarqube

chown -R sonar:sonar /opt/sonarqube


echo "==============================="
echo "Configuring SonarQube"
echo "==============================="

tee /opt/sonarqube/conf/sonar.properties >/dev/null <<EOF

sonar.jdbc.username=$SONAR_DB_USER
sonar.jdbc.password=$SONAR_DB_PASSWORD
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

tee /etc/security/limits.d/99-sonarqube.conf >/dev/null <<EOF

sonar soft nofile 131072
sonar hard nofile 131072
sonar soft nproc 8192
sonar hard nproc 8192

EOF


echo "==============================="
echo "Creating SonarQube Systemd Service"
echo "==============================="

tee /etc/systemd/system/sonarqube.service >/dev/null <<EOF

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
echo "SonarQube Service Status"
echo "==============================="

systemctl status sonarqube --no-pager

echo "==============================="
echo "SonarQube Installation Completed"
echo "==============================="

EOT


  # ============================================================
  # Tags
  # ============================================================

  tags = {
    Name        = "Server-Inventory-Sonarqube"
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
