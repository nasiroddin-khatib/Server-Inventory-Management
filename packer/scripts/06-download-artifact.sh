#!/bin/bash

set -Eeuo pipefail

echo "========================================="
echo " Downloading Application Artifact"
echo "========================================="

: "${ARTIFACT_URL:?ARTIFACT_URL is required}"
: "${NEXUS_USERNAME:?NEXUS_USERNAME is required}"
: "${NEXUS_PASSWORD:?NEXUS_PASSWORD is required}"

DOWNLOAD_DIR="/tmp"

ARTIFACT_NAME="${APPLICATION_NAME}.war"

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --user "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
    "${ARTIFACT_URL}" \
    --output "${DOWNLOAD_DIR}/${ARTIFACT_NAME}"

if [[ ! -s "${DOWNLOAD_DIR}/${ARTIFACT_NAME}" ]]; then
    echo "Artifact download failed."
    exit 1
fi

echo "Artifact downloaded successfully."
