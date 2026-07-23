#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Validating Golden AMI"
echo "========================================="

TOMCAT_HOME="/opt/tomcat"
APPLICATION_NAME="${APPLICATION_NAME:-server-inventory}"

check_command() {
    local command=$1

    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "Validation failed: ${command} is not installed."
        exit 1
    fi
}

echo "Checking Java..."
check_command java

echo "Checking Tomcat installation..."

if [[ ! -d "${TOMCAT_HOME}" ]]; then
    echo "Validation failed: Tomcat directory not found."
    exit 1
fi

echo "Checking Tomcat service..."

systemctl is-enabled tomcat >/dev/null

systemctl is-active --quiet tomcat

echo "Checking CloudWatch Agent..."

systemctl is-enabled amazon-cloudwatch-agent >/dev/null

systemctl is-active --quiet amazon-cloudwatch-agent

echo "Checking deployed application..."

if [[ ! -f "${TOMCAT_HOME}/webapps/ROOT.war" ]]; then
    echo "Validation failed: ROOT.war not found."
    exit 1
fi

echo "Checking CloudWatch configuration..."

if [[ ! -f "/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json" ]]; then
    echo "Validation failed: CloudWatch configuration missing."
    exit 1
fi

echo "Checking required directories..."

required_dirs=(
    "${TOMCAT_HOME}/logs"
    "${TOMCAT_HOME}/temp"
    "${TOMCAT_HOME}/work"
    "${TOMCAT_HOME}/webapps"
)

for dir in "${required_dirs[@]}"; do
    if [[ ! -d "${dir}" ]]; then
        echo "Validation failed: ${dir} does not exist."
        exit 1
    fi
done

echo "Checking disk space..."

df -h

echo "Checking Java version..."

java -version

echo "Golden AMI validation completed successfully."
