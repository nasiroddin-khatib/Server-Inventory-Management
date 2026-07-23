#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Deploying Application"
echo "========================================="

TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

APPLICATION_NAME="${APPLICATION_NAME:?APPLICATION_NAME is required}"

ARTIFACT="/tmp/${APPLICATION_NAME}.war"

TARGET_WAR="${TOMCAT_HOME}/webapps/ROOT.war"

ROOT_DIR="${TOMCAT_HOME}/webapps/ROOT"

if [[ ! -f "${ARTIFACT}" ]]; then
    echo "Artifact not found: ${ARTIFACT}"
    exit 1
fi

echo "Stopping Tomcat..."
systemctl stop tomcat

echo "Cleaning previous deployment..."
rm -rf "${ROOT_DIR}"
rm -f "${TARGET_WAR}"

rm -rf "${TOMCAT_HOME}/work"/*
rm -rf "${TOMCAT_HOME}/temp"/*

echo "Deploying new application..."
cp "${ARTIFACT}" "${TARGET_WAR}"

chown "${TOMCAT_USER}:${TOMCAT_GROUP}" "${TARGET_WAR}"
chmod 644 "${TARGET_WAR}"

echo "Starting Tomcat..."
systemctl start tomcat

echo "Waiting for application deployment..."

for i in {1..30}; do
    if systemctl is-active --quiet tomcat; then
        if [[ -d "${ROOT_DIR}" ]]; then
            echo "Application deployed successfully."
            exit 0
        fi
    fi
    sleep 2
done

echo "Application deployment failed."

journalctl -u tomcat --no-pager -n 50

exit 1
