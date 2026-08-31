pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'
            }
        }

        stage('Terraform Format and Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform fmt -recursive
                        terraform init
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform - SonarQube Infrastructure') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform apply \
                          -target=aws_security_group.sonarqube_sg \
                          -target=aws_vpc_security_group_ingress_rule.sonarqube_http \
                          -target=aws_vpc_security_group_egress_rule.sonarqube_all_outbound \
                          -target=aws_iam_role.sonarqube_role \
                          -target=aws_iam_role_policy.sonarqube_secrets_access \
                          -target=aws_iam_role_policy_attachment.sonarqube_ssm \
                          -target=aws_iam_instance_profile.sonarqube_profile \
                          -target=aws_instance.sonarqube \
                          -auto-approve
                    '''
                }
            }
        }

        stage('Wait for SonarQube') {
            steps {
                sh '''
                    set -e

                    SONAR_IP=$(aws ec2 describe-instances \
                      --filters \
                        "Name=tag:Name,Values=Server-Inventory-Sonarqube" \
                        "Name=instance-state-name,Values=running" \
                      --query 'Reservations[0].Instances[0].PublicIpAddress' \
                      --output text)

                    if [ -z "$SONAR_IP" ] || [ "$SONAR_IP" = "None" ]; then
                        echo "ERROR: SonarQube public IP was not found."
                        exit 1
                    fi

                    echo "SonarQube IP: $SONAR_IP"

                    for i in $(seq 1 30); do

                        STATUS=$(curl -s \
                          "http://$SONAR_IP:9000/api/system/status" \
                          | jq -r '.status' 2>/dev/null || true)

                        echo "SonarQube status: $STATUS"

                        if [ "$STATUS" = "UP" ]; then
                            echo "SonarQube is ready."
                            exit 0
                        fi

                        sleep 10

                    done

                    echo "ERROR: SonarQube did not become ready."
                    exit 1
                '''
            }
        }

        stage('Build and Test') {
            steps {
                dir('backend') {
                    sh 'mvn clean test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('sonarqube-server') {
                        sh 'mvn sonar:sonar'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Terraform - Base Infrastructure') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform apply \
                          -target=aws_subnet.public_subnet_2 \
                          -target=aws_subnet.private_subnet_1 \
                          -target=aws_subnet.private_subnet_2 \
                          -target=aws_eip.nat_eip \
                          -target=aws_nat_gateway.nat_gateway \
                          -target=aws_route_table.public_route_table \
                          -target=aws_route_table.private_route_table \
                          -target=aws_route_table_association.public_subnet_2 \
                          -target=aws_route_table_association.private_subnet_1 \
                          -target=aws_route_table_association.private_subnet_2 \
                          -target=aws_security_group.packer_sg \
                          -target=aws_iam_role.backend_role \
                          -target=aws_iam_role_policy_attachment.backend_ssm \
                          -target=aws_iam_role_policy_attachment.backend_cloudwatch \
                          -target=aws_iam_instance_profile.backend_instance_profile \
                          -target=aws_s3_bucket.frontend \
                          -target=aws_secretsmanager_secret.nexus_credentials \
                          -target=aws_iam_role.nexus_role \
                          -target=aws_iam_role_policy_attachment.nexus_ssm \
                          -target=aws_iam_instance_profile.nexus_profile \
                          -target=aws_instance.nexus \
                          -target=local_file.backend_pom \
                          -auto-approve
                    '''
                }
            }
        }

        stage('Configure Nexus Repository') {
            steps {
                input(
                    message: '''
Nexus Repository Configuration Required

Terraform has created the Nexus server.

1. Open the Nexus Repository Manager UI.
2. Log in to Nexus.
3. Create the hosted Maven repository required by this project.
4. Verify that the repository is available.
5. Return to Jenkins.
6. Click Proceed.
''',
                    ok: 'Repository Created - Continue'
                )
            }
        }

        stage('Enter Nexus Credentials') {
            steps {
                input(
                    message: '''
Nexus Credentials Required

1. Open AWS Secrets Manager.
2. Open server-inventory/nexus-credentials.
3. Store the Nexus username.
4. Store the Nexus password.
5. Save the secret.
6. Return to Jenkins.
7. Click Proceed.
''',
                    ok: 'Credentials Stored - Continue'
                )
            }
        }

        stage('Configure Nexus Credentials') {
            steps {
                sh '''
                    set -e

                    SECRET_JSON=$(aws secretsmanager get-secret-value \
                        --secret-id "server-inventory/nexus-credentials" \
                        --query SecretString \
                        --output text)

                    if [ -z "$SECRET_JSON" ] || [ "$SECRET_JSON" = "None" ]; then
                        echo "Nexus secret is empty or does not exist."
                        exit 1
                    fi

                    NEXUS_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
                    NEXUS_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

                    if [ -z "$NEXUS_USERNAME" ] || [ "$NEXUS_USERNAME" = "null" ]; then
                        echo "Nexus username is missing."
                        exit 1
                    fi

                    if [ -z "$NEXUS_PASSWORD" ] || [ "$NEXUS_PASSWORD" = "null" ]; then
                        echo "Nexus password is missing."
                        exit 1
                    fi

                    export nexus_username="$NEXUS_USERNAME"
                    export nexus_password="$NEXUS_PASSWORD"

                    envsubst < jenkins/settings.xml.tpl > jenkins/settings.xml

                    chmod 600 jenkins/settings.xml

                    mkdir -p "$HOME/.m2"

                    cp jenkins/settings.xml "$HOME/.m2/settings.xml"

                    chmod 600 "$HOME/.m2/settings.xml"

                    unset SECRET_JSON
                    unset NEXUS_USERNAME
                    unset NEXUS_PASSWORD
                    unset nexus_username
                    unset nexus_password
                '''
            }
        }

        stage('Deploy to Nexus') {
            steps {
                dir('backend') {
                    sh 'mvn deploy'
                }
            }
        }

        stage('Build Backend AMI') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'packer-ssh-key',
                        variable: 'PACKER_SSH_KEY'
                    )
                ]) {
                    sh '''
                        set -e

                        cd packer

                        packer init .

                        packer validate \
                          -var-file=terraform.pkrvars.hcl \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .

                        packer build \
                          -var-file=terraform.pkrvars.hcl \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .

                        AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d: -f2)

                        if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "null" ]; then
                            echo "Failed to obtain AMI ID."
                            exit 1
                        fi

                        echo "$AMI_ID" > ../backend-ami-id.txt
                    '''
                }
            }
        }

        stage('Terraform - Update Infrastructure') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        AMI_ID=$(cat ../backend-ami-id.txt)

                        if [ -z "$AMI_ID" ]; then
                            echo "Backend AMI ID is empty."
                            exit 1
                        fi

                        terraform init
                        terraform validate

                        terraform plan \
                          -var="backend_ami_id=$AMI_ID" \
                          -out=tfplan

                        terraform apply \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }
    }

    post {

        always {
            sh '''
                rm -f jenkins/settings.xml
                rm -f "$HOME/.m2/settings.xml"
                rm -f terraform/tfplan
                rm -f backend-ami-id.txt
            '''
        }

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins Console Output.'
        }
    }
}
