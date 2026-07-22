#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/monitoring-bootstrap.log)
exec 2>&1

echo "========================================="
echo "Monitoring Server Bootstrap Started"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

apt-get install -y \
curl \
wget \
git \
unzip \
tar \
jq \
gnupg \
ca-certificates \
software-properties-common

#########################################################
# Section 2 - Install Prometheus
#########################################################

echo "Installing Prometheus..."

PROMETHEUS_VERSION="2.55.1"

useradd --no-create-home --shell /usr/sbin/nologin prometheus || true

mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

cd /tmp

wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

tar -xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

cp -r consoles /etc/prometheus
cp -r console_libraries /etc/prometheus

chown -R prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus

chmod 755 /usr/local/bin/prometheus
chmod 755 /usr/local/bin/promtool

echo "Prometheus installation completed."

#########################################################
# Section 3 - Configure Prometheus
#########################################################

echo "Configuring Prometheus..."

cat <<EOF >/etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: "prometheus"

    static_configs:
      - targets:
          - localhost:9090

  - job_name: "springboot"

    metrics_path: /server-inventory/actuator/prometheus

    ec2_sd_configs:
      - region: ap-south-1
        port: 8080

    relabel_configs:

      - source_labels:
          - __meta_ec2_tag_Role
        regex: backend
        action: keep

      - source_labels:
          - __meta_ec2_private_ip
        target_label: __address__
        replacement: \$1:8080

      - source_labels:
          - __meta_ec2_instance_id
        target_label: instance

      - source_labels:
          - __meta_ec2_tag_Name
        target_label: instance_name

      - source_labels:
          - __meta_ec2_availability_zone
        target_label: availability_zone
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
After=network.target

[Service]

User=prometheus
Group=prometheus

Type=simple

ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--storage.tsdb.retention.time=15d \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

Restart=always
RestartSec=5

LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable prometheus

systemctl start prometheus

echo "Prometheus service started."

#########################################################
# Section 4 - Install Grafana
#########################################################

echo "Installing Grafana..."

mkdir -p /etc/apt/keyrings

wget -q -O - https://apt.grafana.com/gpg.key | \
gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
> /etc/apt/sources.list.d/grafana.list

apt-get update -y

apt-get install -y grafana

systemctl daemon-reload

systemctl enable grafana-server

systemctl start grafana-server

echo "Grafana installation completed."

#########################################################
# Section 5 - Configure Grafana Datasource
#########################################################

echo "Configuring Grafana datasource..."

mkdir -p /etc/grafana/provisioning/datasources

cat <<EOF >/etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

deleteDatasources:
  - name: Prometheus
    orgId: 1

datasources:

  - name: Prometheus

    type: prometheus

    access: proxy

    orgId: 1

    url: http://localhost:9090

    isDefault: true

    editable: false

    version: 1
EOF

systemctl restart grafana-server

echo "Grafana datasource configured."

#########################################################
# Section 6 - Configure Grafana Dashboards
#########################################################

echo "Configuring Grafana dashboards..."

mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /var/lib/grafana/dashboards

cat <<EOF >/etc/grafana/provisioning/dashboards/dashboard.yaml
apiVersion: 1

providers:

  - name: 'Application Dashboards'

    orgId: 1

    folder: 'Application Monitoring'

    type: file

    disableDeletion: false

    editable: true

    updateIntervalSeconds: 30

    allowUiUpdates: true

    options:
      path: /var/lib/grafana/dashboards
EOF

systemctl restart grafana-server

echo "Grafana dashboard provisioning completed."

#########################################################
# Section 7 - Install CloudWatch Agent
#########################################################

echo "Installing Amazon CloudWatch Agent..."

cd /tmp

wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

dpkg -i amazon-cloudwatch-agent.deb

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

echo "CloudWatch Agent installed."

cat <<EOF >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },

  "metrics": {

    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}",
      "InstanceType": "\${aws:InstanceType}",
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}"
    },

    "metrics_collected": {

      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ]
      },

      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "*"
        ]
      },

      "diskio": {},

      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },

      "swap": {
        "measurement": [
          "swap_used_percent"
        ]
      },

      "net": {}
    }
  },

  "logs": {

    "logs_collected": {

      "files": {

        "collect_list": [

          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/monitoring/syslog",
            "log_stream_name": "{instance_id}"
          },

          {
            "file_path": "/var/log/monitoring-bootstrap.log",
            "log_group_name": "/monitoring/bootstrap",
            "log_stream_name": "{instance_id}"
          }

        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s

systemctl enable amazon-cloudwatch-agent

echo "CloudWatch Agent configured."

#########################################################
# Section 8 - Verify Installation
#########################################################

echo "Verifying Monitoring Stack..."

sleep 10

echo "----------------------------------------"
echo "Prometheus Status"
echo "----------------------------------------"

if systemctl is-active --quiet prometheus; then
    echo "Prometheus is running."
else
    echo "ERROR: Prometheus failed to start."
    journalctl -u prometheus --no-pager -n 50
    exit 1
fi

echo "----------------------------------------"
echo "Grafana Status"
echo "----------------------------------------"

if systemctl is-active --quiet grafana-server; then
    echo "Grafana is running."
else
    echo "ERROR: Grafana failed to start."
    journalctl -u grafana-server --no-pager -n 50
    exit 1
fi

echo "----------------------------------------"
echo "CloudWatch Agent Status"
echo "----------------------------------------"

if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "CloudWatch Agent is running."
else
    echo "ERROR: CloudWatch Agent failed to start."
    journalctl -u amazon-cloudwatch-agent --no-pager -n 50
    exit 1
fi

echo "----------------------------------------"
echo "Checking Listening Ports"
echo "----------------------------------------"

ss -tulnp | grep 9090 || true
ss -tulnp | grep 3000 || true

echo "----------------------------------------"
echo "Prometheus Health Check"
echo "----------------------------------------"

curl -fs http://localhost:9090/-/healthy

echo "----------------------------------------"
echo "Grafana Health Check"
echo "----------------------------------------"

curl -fs http://localhost:3000/api/health

echo "Monitoring Stack verification completed successfully."

#########################################################
# Section 9 - Cleanup
#########################################################

echo "Cleaning temporary files..."

rm -rf /tmp/prometheus*
rm -f /tmp/amazon-cloudwatch-agent.deb

apt-get autoremove -y
apt-get autoclean

echo "Cleanup completed."

echo
echo "==========================================="
echo " Monitoring Server Setup Completed"
echo "==========================================="
echo
echo "Services:"
echo "  Prometheus : http://$(hostname -I | awk '{print $1}'):9090"
echo "  Grafana    : http://$(hostname -I | awk '{print $1}'):3000"
echo
echo "Grafana Login:"
echo "  Username : admin"
echo "  Password : admin"
echo
echo "CloudWatch Agent : Running"
echo "Bootstrap Log:"
echo "  /var/log/monitoring-bootstrap.log"
echo
echo "==========================================="

