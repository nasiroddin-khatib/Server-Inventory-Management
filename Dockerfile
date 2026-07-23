FROM jenkins/jenkins:lts

USER root

############################################
# Install Required Packages
############################################
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        wget \
        unzip \
        zip \
        tree \
        jq \
        sudo \
        openssh-client \
        ca-certificates \
        gnupg \
        maven \
        python3 \
        python3-pip \
        ansible && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

############################################
# Install AWS CLI v2
############################################
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

############################################
# Install Terraform
############################################
RUN mkdir -p /tmp/terraform && \
    wget -q -O /tmp/terraform/terraform.zip \
    https://releases.hashicorp.com/terraform/1.13.0/terraform_1.13.0_linux_amd64.zip && \
    unzip -q /tmp/terraform/terraform.zip -d /tmp/terraform && \
    mv /tmp/terraform/terraform /usr/local/bin/ && \
    chmod +x /usr/local/bin/terraform && \
    rm -rf /tmp/terraform

############################################
# Install Packer
############################################
RUN mkdir -p /tmp/packer && \
    wget -q -O /tmp/packer/packer.zip \
    https://releases.hashicorp.com/packer/1.14.2/packer_1.14.2_linux_amd64.zip && \
    unzip -q /tmp/packer/packer.zip -d /tmp/packer && \
    mv /tmp/packer/packer /usr/local/bin/ && \
    chmod +x /usr/local/bin/packer && \
    rm -rf /tmp/packer

############################################
# Verify Installations
############################################
RUN git --version && \
    java -version && \
    mvn -version && \
    aws --version && \
    terraform version && \
    packer version && \
    ansible --version
