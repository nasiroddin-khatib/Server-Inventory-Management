#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Installing Amazon CloudWatch Agent"
echo "========================================="

dnf install -y amazon-cloudwatch-agent

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cp /tmp/cloudwatch-config.json \
   /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

systemctl enable amazon-cloudwatch-agent

echo "CloudWatch Agent installation completed successfully."
