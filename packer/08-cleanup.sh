#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Cleaning System Before AMI Creation"
echo "========================================="

echo "Cleaning package manager cache..."
dnf clean all

echo "Removing temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "Removing SSH host keys..."
rm -f /etc/ssh/ssh_host_*

echo "Cleaning machine-id..."
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

echo "Cleaning cloud-init state..."
cloud-init clean --logs || true

echo "Removing shell history..."
history -c || true
rm -f /root/.bash_history
rm -f /home/ec2-user/.bash_history || true

echo "Removing log files..."
find /var/log -type f -exec truncate -s 0 {} \;

echo "Syncing filesystem..."
sync

echo "Cleanup completed successfully."
