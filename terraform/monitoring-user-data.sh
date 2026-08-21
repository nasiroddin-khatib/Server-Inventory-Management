#!/bin/bash

set -e

############################################
# System Update
############################################

apt update -y


############################################
# Dependencies
############################################

apt install -y wget tar curl


############################################
# PROMETHEUS
############################################

PROM_VERSION="2.55.1"


echo "Installing Prometheus..."


############################################
# Prometheus User
############################################

id prometheus &>/dev/null || \
useradd --system \
        --no-create-home \
        --shell /usr/sbin/nologin \
        prometheus


############################################
# Directories
############################################

mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus


############################################
# Download Prometheus
############################################

cd /tmp

wget -q \
  -O prometheus.tar.gz \
  https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz


############################################
# Extract
############################################

rm -rf prometheus-${PROM_VERSION}.linux-amd64

tar -xzf prometheus.tar.gz

cd prometheus-${PROM_VERSION}.linux-amd64


############################################
# Install binaries
############################################

cp prometheus /usr/local/bin/

cp promtool /usr/local/bin/


############################################
# Permissions
############################################

chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool


############################################
# PROMETHEUS CONFIGURATION
############################################

cat > /etc/prometheus/prometheus.yml <<'EOF'

global:

  scrape_interval: 15s

  evaluation_interval: 15s


scrape_configs:

  ##########################################
  # Spring Boot Applications
  ##########################################

  - job_name: "server-inventory"

    metrics_path: /server-inventory/actuator/prometheus

    ec2_sd_configs:

      - region: ap-south-1

        port: 8080

        refresh_interval: 30s

    relabel_configs:

      ######################################
      # Only Backend Instances
      ######################################

      - source_labels:
          - __meta_ec2_tag_Role

        regex: backend

        action: keep


      ######################################
      # Only Running Instances
      ######################################

      - source_labels:
          - __meta_ec2_instance_state

        regex: running

        action: keep


      ######################################
      # Instance ID Label
      ######################################

      - source_labels:
          - __meta_ec2_instance_id

        target_label: instance_id


      ######################################
      # Availability Zone
      ######################################

      - source_labels:
          - __meta_ec2_availability_zone

        target_label: availability_zone


      ######################################
      # Backend Name
      ######################################

      - source_labels:
          - __meta_ec2_tag_Name

        target_label: instance_name

EOF


############################################
# Prometheus Permissions
############################################

chown -R prometheus:prometheus /etc/prometheus

chown -R prometheus:prometheus /var/lib/prometheus


############################################
# Prometheus Service
############################################

cat > /etc/systemd/system/prometheus.service <<'EOF'

[Unit]

Description=Prometheus

After=network.target


[Service]

User=prometheus

Group=prometheus

Type=simple

ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus

Restart=always

RestartSec=5


[Install]

WantedBy=multi-user.target

EOF


############################################
# Start Prometheus
############################################

systemctl daemon-reload

systemctl enable prometheus

systemctl restart prometheus


############################################
# GRAFANA
############################################

echo "Installing Grafana..."


apt install -y \
  software-properties-common \
  apt-transport-https \
  wget \
  gpg


############################################
# Grafana GPG Key
############################################

wget -q -O - https://apt.grafana.com/gpg.key | \
gpg --dearmor \
-o /usr/share/keyrings/grafana.gpg


############################################
# Grafana Repository
############################################

echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
> /etc/apt/sources.list.d/grafana.list


############################################
# Install Grafana
############################################

apt update -y

apt install -y grafana


############################################
# Start Grafana
############################################

systemctl daemon-reload

systemctl enable grafana-server

systemctl restart grafana-server


############################################
# Cleanup
############################################

rm -f /tmp/prometheus.tar.gz

rm -rf /tmp/prometheus-${PROM_VERSION}.linux-amd64


############################################
# Status
############################################

systemctl --no-pager --full status prometheus || true

systemctl --no-pager --full status grafana-server || true


echo ""
echo "=========================================="
echo "Monitoring Server Ready"
echo "=========================================="
echo "Prometheus : http://SERVER-IP:9090"
echo "Grafana    : http://SERVER-IP:3000"
echo "=========================================="


############################################
# Prometheus Configuration
############################################

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:

  - job_name: "backend"

    metrics_path: "/server-inventory/actuator/prometheus"

    ec2_sd_configs:
      - region: "ap-south-1"
        port: 8080

        filters:
          - name: "tag:role"
            values:
              - "backend"

    relabel_configs:

      - source_labels:
          - "__meta_ec2_private_ip"
        target_label: "__address__"
        replacement: "$1:8080"

      - source_labels:
          - "__meta_ec2_tag_Name"
        target_label: "instance_name"

      - source_labels:
          - "__meta_ec2_availability_zone"
        target_label: "availability_zone"
EOF


############################################
# Set Permissions
############################################

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml


############################################
# Validate Prometheus Configuration
############################################

sudo promtool check config /etc/prometheus/prometheus.yml


############################################
# Restart Prometheus
############################################

sudo systemctl restart prometheus


############################################
# Check Prometheus
############################################

sudo systemctl is-active --quiet prometheus

echo "==========================================="
echo "Prometheus configured successfully"
echo "Backend EC2 dynamic discovery enabled"
echo "==========================================="
