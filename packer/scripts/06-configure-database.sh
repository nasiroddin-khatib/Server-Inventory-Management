#!/bin/bash
set -e

SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

DB_ENDPOINT=$(echo "$SECRET" | jq -r .endpoint)
DB_NAME=$(echo "$SECRET" | jq -r .database)
DB_USERNAME=$(echo "$SECRET" | jq -r .username)
DB_PASSWORD=$(echo "$SECRET" | jq -r .password)

cat >/opt/tomcat/bin/setenv.sh <<EOF
export DB_URL=jdbc:postgresql://${DB_ENDPOINT}:5432/${DB_NAME}
export DB_USERNAME=${DB_USERNAME}
export DB_PASSWORD=${DB_PASSWORD}
EOF

chmod +x /opt/tomcat/bin/setenv.sh
chown tomcat:tomcat /opt/tomcat/bin/setenv.sh
