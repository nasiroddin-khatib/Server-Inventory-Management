#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Installing Apache Tomcat"
echo "========================================="

TOMCAT_VERSION="10.1.57"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"
TOMCAT_HOME="/opt/tomcat"

if ! id "${TOMCAT_USER}" >/dev/null 2>&1; then
    useradd \
        --system \
        --create-home \
        --home-dir ${TOMCAT_HOME} \
        --shell /sbin/nologin \
        ${TOMCAT_USER}
fi

cd /tmp

wget -q https://downloads.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

mkdir -p ${TOMCAT_HOME}

tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    -C ${TOMCAT_HOME} \
    --strip-components=1

chown -R ${TOMCAT_USER}:${TOMCAT_GROUP} ${TOMCAT_HOME}

chmod -R 755 ${TOMCAT_HOME}

cat >/etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat Application Server
After=network.target

[Service]

Type=forking

User=${TOMCAT_USER}
Group=${TOMCAT_GROUP}

Environment=JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
Environment=CATALINA_PID=${TOMCAT_HOME}/temp/tomcat.pid
Environment=CATALINA_HOME=${TOMCAT_HOME}
Environment=CATALINA_BASE=${TOMCAT_HOME}
Environment=CATALINA_OPTS=-Xms512M -Xmx1024M
Environment=JAVA_OPTS=-Djava.security.egd=file:/dev/urandom

ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh

SuccessExitStatus=143

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable tomcat

systemctl start tomcat

echo "Tomcat installation completed successfully."
