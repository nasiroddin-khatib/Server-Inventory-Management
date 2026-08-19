# ============================================================
# Nexus Repository EC2 IAM Role
# Used for AWS Systems Manager - SSH-less management
# ============================================================

resource "aws_iam_role" "nexus_role" {
  name = "server-inventory-nexus-role"

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
    Name      = "server-inventory-nexus-role"
    Project   = "Server-Inventory"
    ManagedBy = "Terraform"
  }
}


# ============================================================
# AWS Systems Manager Permission
# Allows SSH-less management of Nexus EC2
# ============================================================

resource "aws_iam_role_policy_attachment" "nexus_ssm" {
  role       = aws_iam_role.nexus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# EC2 Instance Profile
# ============================================================

resource "aws_iam_instance_profile" "nexus_profile" {
  name = "server-inventory-nexus-profile"

  role = aws_iam_role.nexus_role.name
}


# ============================================================
# Nexus Repository EC2 Instance
# ============================================================

resource "aws_instance" "nexus" {

  # Amazon Linux 2023 x86_64
  ami = "ami-0ac7b260cf76d8865"

  # 2 vCPU / 4 GiB RAM
  instance_type = "c7i-flex.large"

  # Existing Terraform public subnet
  subnet_id = aws_subnet.public_subnet_1.id

  # Existing Nexus security group
  vpc_security_group_ids = [
    aws_security_group.nexus_sg.id
  ]

  # Assign public IP
  associate_public_ip_address = true

  # Existing key pair
  key_name = "mykey"

  # Attach IAM role
  iam_instance_profile = aws_iam_instance_profile.nexus_profile.name


  # ==========================================================
  # Root Volume
  # ==========================================================

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }


  # ==========================================================
  # Nexus Installation
  # ==========================================================

  user_data = <<-EOT
#!/bin/bash

set -e


echo "========================================"
echo "NEXUS INSTALLATION STARTED"
echo "========================================"


# ==========================================================
# Variables
# ==========================================================

NEXUS_VERSION="3.79.0-09"
NEXUS_TAR="nexus-unix-x86-64-3.79.0-09.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.79.0-09.tar.gz"


# ==========================================================
# Update Packages
# ==========================================================

echo "========================================"
echo "Updating Packages"
echo "========================================"

dnf update -y


# ==========================================================
# Install Required Packages
# ==========================================================

echo "========================================"
echo "Installing Required Packages"
echo "========================================"

dnf install -y wget tar


# ==========================================================
# Start SSM Agent
# ==========================================================

echo "========================================"
echo "Starting SSM Agent"
echo "========================================"

systemctl enable --now amazon-ssm-agent


# ==========================================================
# Create Nexus User
# ==========================================================

echo "========================================"
echo "Creating Nexus User"
echo "========================================"

if ! id nexus >/dev/null 2>&1; then
    useradd --system --create-home --shell /bin/bash nexus
fi


# ==========================================================
# Create Nexus Data Directory
# ==========================================================

echo "========================================"
echo "Creating Nexus Data Directory"
echo "========================================"

mkdir -p /opt/sonatype-work/nexus3


# ==========================================================
# Download Nexus
# ==========================================================

echo "========================================"
echo "Downloading Nexus Repository"
echo "========================================"

cd /tmp

wget -O "$NEXUS_TAR" "$NEXUS_URL"


# ==========================================================
# Verify Download
# ==========================================================

echo "========================================"
echo "Verifying Nexus Download"
echo "========================================"

ls -lh "$NEXUS_TAR"


# ==========================================================
# Extract Nexus
# ==========================================================

echo "========================================"
echo "Extracting Nexus Repository"
echo "========================================"

tar -xzf "$NEXUS_TAR" -C /opt


# ==========================================================
# Move Nexus To Standard Directory
# ==========================================================

echo "========================================"
echo "Configuring Nexus Directory"
echo "========================================"

mv "/opt/nexus-$NEXUS_VERSION" /opt/nexus


# ==========================================================
# Configure Nexus Runtime User
# ==========================================================

echo "========================================"
echo "Configuring Nexus Runtime User"
echo "========================================"

cat > /opt/nexus/bin/nexus.rc <<'EOF'
run_as_user="nexus"
EOF


# ==========================================================
# Set Ownership
# ==========================================================

echo "========================================"
echo "Setting Nexus Ownership"
echo "========================================"

chown -R nexus:nexus /opt/nexus
chown -R nexus:nexus /opt/sonatype-work


# ==========================================================
# Create Nexus Systemd Service
# ==========================================================

echo "========================================"
echo "Creating Nexus Systemd Service"
echo "========================================"

cat > /etc/systemd/system/nexus.service <<'EOF'
[Unit]
Description=Nexus Repository
After=network.target

[Service]
Type=forking

User=nexus
Group=nexus

LimitNOFILE=65536

ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop

Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF


# ==========================================================
# Reload Systemd
# ==========================================================

echo "========================================"
echo "Reloading Systemd"
echo "========================================"

systemctl daemon-reload


# ==========================================================
# Enable Nexus Service
# ==========================================================

echo "========================================"
echo "Enabling Nexus Service"
echo "========================================"

systemctl enable nexus.service


# ==========================================================
# Start Nexus
# ==========================================================

echo "========================================"
echo "Starting Nexus Repository"
echo "========================================"

systemctl start nexus.service


# ==========================================================
# Wait For Nexus
# ==========================================================

echo "========================================"
echo "Waiting For Nexus"
echo "========================================"

sleep 30


# ==========================================================
# Check Nexus Service
# ==========================================================

echo "========================================"
echo "Nexus Service Status"
echo "========================================"

systemctl status nexus.service --no-pager


echo "========================================"
echo "NEXUS INSTALLATION COMPLETED"
echo "========================================"

EOT


# ============================================================
# Tags
# ============================================================

  tags = {
    Name        = "Server-Inventory-Nexus"
    Project     = "Server-Inventory"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
