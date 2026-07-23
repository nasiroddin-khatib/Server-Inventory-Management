#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Configuring Apache Tomcat"
echo "========================================="

TOMCAT_HOME="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"

CONTEXT_FILE="${TOMCAT_HOME}/webapps/manager/META-INF/context.xml"

if [[ -f "${CONTEXT_FILE}" ]]; then

    cp "${CONTEXT_FILE}" "${CONTEXT_FILE}.bak"

    sed -i '/RemoteAddrValve/d' "${CONTEXT_FILE}"

fi

LOCALHOST_CONTEXT="${TOMCAT_HOME}/webapps/host-manager/META-INF/context.xml"

if [[ -f "${LOCALHOST_CONTEXT}" ]]; then

    cp "${LOCALHOST_CONTEXT}" "${LOCALHOST_CONTEXT}.bak"

    sed -i '/RemoteAddrValve/d' "${LOCALHOST_CONTEXT}"

fi

mkdir -p ${TOMCAT_HOME}/logs

mkdir -p ${TOMCAT_HOME}/temp

mkdir -p ${TOMCAT_HOME}/work

mkdir -p ${TOMCAT_HOME}/webapps

chown -R ${TOMCAT_USER}:${TOMCAT_GROUP} ${TOMCAT_HOME}

chmod -R 755 ${TOMCAT_HOME}

systemctl restart tomcat

echo "Tomcat configuration completed successfully."
