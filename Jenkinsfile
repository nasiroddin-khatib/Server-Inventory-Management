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
                         
                          -target=aws_security_group.packer_sg \
                          -target=aws_iam_role.backend_role \
                          -target=aws_iam_role_policy_attachment.backend_ssm \
                          -target=aws_iam_role_policy_attachment.backend_cloudwatch \
                          -target=aws_iam_instance_profile.backend_instance_profile \
                          -target=aws_s3_bucket.frontend \
                          -target=aws_secretsmanager_secret.nexus_credentials \                          
                          -target=aws_iam_role_policy_attachment.jenkins_ssm \                       
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
========================================
Nexus Repository Configuration Required
========================================

Terraform has created the Nexus server.

Now:

1. Open the Nexus Repository Manager UI.
2. Wait until Nexus is fully started.
3. Log in to Nexus.
4. Create the hosted Maven repository required
   by this project.
5. Verify that the repository is available.
6. Return to Jenkins.
7. Click "Proceed".

========================================
''',
                    ok: 'Nexus Repository Created - Continue'
                )
            }
        }

        stage('Enter Nexus Credentials') {
            steps {
                input(
                    message: '''
========================================
Nexus Credentials Required
========================================

Open AWS Secrets Manager and:

1. Open: server-inventory/nexus-credentials
2. Store the Nexus username.
3. Store the Nexus password.
4. Save the secret.
5. Return to Jenkins.
6. Click "Proceed".

========================================
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

        stage('Package') {
            steps {
                dir('backend') {
                    sh 'mvn package'
                }
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
