#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Installing Amazon Corretto Java 17 LTS"
echo "========================================="

dnf -y update

dnf install -y \
    java-17-amazon-corretto-devel \
    wget \
    curl \
    unzip \
    tar

JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto"

if ! grep -q "JAVA_HOME" /etc/profile; then
cat <<EOF >> /etc/profile

export JAVA_HOME=${JAVA_HOME}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
fi

export JAVA_HOME=${JAVA_HOME}
export PATH=$JAVA_HOME/bin:$PATH

echo "Java Version"

java -version

javac -version

echo "Java installation completed successfully."
