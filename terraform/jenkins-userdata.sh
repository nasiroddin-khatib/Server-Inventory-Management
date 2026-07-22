#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/jenkins-bootstrap.log)
exec 2>&1

echo "========================================="
echo "Jenkins Bootstrap Started"
echo "========================================="

dnf update -y

echo "Installing required packages..."

dnf install -y \
docker \
git \
wget \
curl \
unzip \
zip \
tar \
jq \
vim \
which

echo "Starting Docker..."

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

echo "Docker Version"
docker --version

echo "Git Version"
git --version

echo "========================================="
echo "Section 1 Completed"
echo "========================================="

#########################################################
# Section 2 - Prepare Jenkins Workspace
#########################################################

echo "Preparing Jenkins workspace..."

mkdir -p /opt/jenkins

cd /opt/jenkins

echo "Workspace created."

echo "========================================="
echo "Section 2 Completed"
echo "========================================="

#########################################################
# Section 3 - Create Jenkins Dockerfile
#########################################################

echo "Creating Jenkins Dockerfile..."

cat >/opt/jenkins/Dockerfile <<'EOF'
FROM jenkins/jenkins:2.516.2-lts-jdk17

USER root

RUN apt-get update && apt-get install -y \
curl \
wget \
git \
unzip \
zip \
tar \
jq \
vim \
nodejs \
npm \
docker.io \
maven \
openjdk-17-jdk \
ca-certificates \
gnupg \
lsb-release \
openssh-client \
net-tools \
&& rm -rf /var/lib/apt/lists/*

#################################################
# kubectl
#################################################

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
rm kubectl

#################################################
# AWS CLI
#################################################

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o awscliv2.zip && \
unzip awscliv2.zip && \
./aws/install && \
rm -rf aws awscliv2.zip

#################################################
# Terraform
#################################################

RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null && \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/hashicorp.list && \
apt-get update && \
apt-get install -y terraform

#################################################
# Trivy
#################################################

RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor | \
tee /usr/share/keyrings/trivy.gpg >/dev/null && \
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/trivy.list && \
apt-get update && \
apt-get install -y trivy

#################################################
# Sonar Scanner
#################################################

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-5.0.1.3006-linux.zip && \
unzip sonar-scanner-5.0.1.3006-linux.zip && \
mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
rm sonar-scanner-5.0.1.3006-linux.zip

ENV PATH="$PATH:/opt/sonar-scanner/bin"

#################################################
# OWASP Dependency Check
#################################################

RUN wget https://github.com/jeremylong/DependencyCheck/releases/download/v9.0.9/dependency-check-9.0.9-release.zip && \
unzip dependency-check-9.0.9-release.zip && \
mv dependency-check /opt/dependency-check && \
rm dependency-check-9.0.9-release.zip

ENV PATH="$PATH:/opt/dependency-check/bin"

#################################################
# Docker Permissions
#################################################

RUN groupadd -f docker && usermod -aG docker jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN jenkins-plugin-cli \
    --plugin-file /usr/share/jenkins/ref/plugins.txt

USER jenkins
EOF

echo "Dockerfile created."

echo "========================================="
echo "Section 3 Completed"
echo "========================================="

#########################################################
# Section 4 - Build and Run Jenkins Container
#########################################################

echo "Building custom Jenkins image..."

cd /opt/jenkins

docker build --pull -t custom-jenkins:latest .

echo "Creating Jenkins volume..."

docker volume create jenkins_home

echo "Starting Jenkins container..."

docker run -d \
--name custom-jenkins \
--restart unless-stopped \
-p 8080:8080 \
-p 50000:50000 \
-v jenkins_home:/var/jenkins_home \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/bin/docker:/usr/bin/docker:ro \
-u root \
custom-jenkins:latest

echo "Waiting for Jenkins to start..."

sleep 30

echo "========================================="
echo "Running Containers"
echo "========================================="

docker ps

echo "========================================="
echo "Section 4 Completed"
echo "========================================="

#########################################################
# Section 5 - Verify Jenkins
#########################################################

echo "Verifying Jenkins..."

if docker ps --format '{{.Names}}' | grep -q "^custom-jenkins$"; then
    echo "Jenkins container is running."
else
    echo "ERROR: Jenkins container failed to start."

    docker logs custom-jenkins

    exit 1
fi

echo "Waiting for Jenkins web interface..."

sleep 20

echo "Checking Jenkins HTTP endpoint..."

curl -fs http://localhost:8080/login >/dev/null

echo "Jenkins is responding."

echo
echo "========================================="
echo "Jenkins Information"
echo "========================================="

echo "URL:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

echo
echo "Initial Admin Password:"
echo

docker exec custom-jenkins \
cat /var/jenkins_home/secrets/initialAdminPassword

echo
echo "========================================="
echo "Section 5 Completed"
echo "========================================="

#########################################################
# Section 6 - Final Verification & Cleanup
#########################################################

echo "Performing final verification..."

echo "-----------------------------------------"
echo "Docker Version"
echo "-----------------------------------------"
docker --version

echo "-----------------------------------------"
echo "Jenkins Container"
echo "-----------------------------------------"
docker ps

echo "-----------------------------------------"
echo "Installed Tool Versions"
echo "-----------------------------------------"

docker exec custom-jenkins java -version || true
docker exec custom-jenkins mvn -version || true
docker exec custom-jenkins git --version || true
docker exec custom-jenkins terraform version || true
docker exec custom-jenkins aws --version || true
docker exec custom-jenkins kubectl version --client || true
docker exec custom-jenkins trivy --version || true
docker exec custom-jenkins sonar-scanner --version || true
docker exec custom-jenkins dependency-check.sh --version || true
docker exec custom-jenkins node --version || true
docker exec custom-jenkins npm --version || true

echo "-----------------------------------------"
echo "Cleaning temporary files"
echo "-----------------------------------------"

docker image prune -f

dnf clean all

rm -rf /tmp/*

echo
echo "========================================="
echo " Jenkins Server Setup Completed"
echo "========================================="
echo
echo "Jenkins URL:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo
echo "Container Name:"
echo "custom-jenkins"
echo
echo "Docker Image:"
echo "custom-jenkins:latest"
echo
echo "Bootstrap Log:"
echo "/var/log/jenkins-bootstrap.log"
echo
echo "========================================="

#########################################################
# Section 7 - Create Jenkins Directories
#########################################################

echo "Creating Jenkins directories..."

mkdir -p /opt/jenkins

mkdir -p /opt/jenkins/docker

mkdir -p /opt/jenkins/plugins

mkdir -p /opt/jenkins/casc

mkdir -p /opt/jenkins/init.groovy.d

echo "Directories created."

echo "========================================="
echo "Section 7 Completed"
echo "========================================="
