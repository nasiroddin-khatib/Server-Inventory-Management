#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Configuring Amazon CloudWatch Agent"
echo "========================================="

CONFIG_FILE="/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "CloudWatch configuration file not found."
    exit 1
fi

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a stop || true

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:${CONFIG_FILE} \
    -s

systemctl enable amazon-cloudwatch-agent

systemctl restart amazon-cloudwatch-agent

sleep 5

systemctl is-active --quiet amazon-cloudwatch-agent

echo "CloudWatch Agent configured successfully."
