pipeline {

    agent any

    stages {

        // ============================================
        // Checkout
        // ============================================

        stage('Checkout') {

            steps {

                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'
            }
        }


        // ============================================
        // Wait for Nexus Credentials
        // ============================================

        stage('Enter Nexus Credentials') {

            steps {

                input(
                    message: '''
========================================
Nexus Credentials Required
========================================

Terraform has created the Nexus Secrets Manager secret.

Now:

1. Open AWS Secrets Manager
2. Open: server-inventory/nexus-credentials
3. Store the Nexus username and password
4. Save the secret
5. Come back here
6. Click "Proceed"

========================================
''',
                    ok: 'Credentials Stored - Continue Pipeline'
                )
            }
        }


        // ============================================
        // Configure Nexus Credentials
        // ============================================

        stage('Configure Nexus Credentials') {

            steps {

                sh '''
                    set -e

                    echo "Fetching Nexus credentials from AWS Secrets Manager..."

                    SECRET_JSON=$(aws secretsmanager get-secret-value \
                        --secret-id "server-inventory/nexus-credentials" \
                        --query SecretString \
                        --output text)

                    NEXUS_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
                    NEXUS_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

                    export NEXUS_USERNAME
                    export NEXUS_PASSWORD

                    envsubst < jenkins/settings.xml.tpl > jenkins/settings.xml

                    unset SECRET_JSON
                    unset NEXUS_USERNAME
                    unset NEXUS_PASSWORD

                    echo "Nexus settings.xml generated successfully."
                '''
            }
        }


        // ============================================
        // Build
        // ============================================

        stage('Build') {

            steps {

                dir('backend') {

                    sh 'mvn clean test'
                }
            }
        }


        // ============================================
        // SonarQube Analysis
        // ============================================

        stage('SonarQube Analysis') {

            steps {

                dir('backend') {

                    withSonarQubeEnv('sonarqube-server') {

                        sh 'mvn sonar:sonar'
                    }
                }
            }
        }


        // ============================================
        // Quality Gate
        // ============================================

        stage('Quality Gate') {

            steps {

                timeout(time: 5, unit: 'MINUTES') {

                    waitForQualityGate abortPipeline: true
                }
            }
        }


        // ============================================
        // Package
        // ============================================

        stage('Package') {

            steps {

                dir('backend') {

                    sh 'mvn package'
                }
            }
        }


        // ============================================
        // Deploy to Nexus
        // ============================================

        stage('Deploy to Nexus') {

            steps {

                dir('backend') {

                    sh 'mvn deploy -s ../jenkins/settings.xml'
                }
            }
        }


        // ============================================
        // Packer
        // ============================================

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

                        echo "======================================="
                        echo "Initializing Packer"
                        echo "======================================="

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

                        echo "Created AMI: $AMI_ID"

                        echo "$AMI_ID" > ../backend-ami-id.txt
                    '''
                }
            }
        }


        // ============================================
        // Terraform
        // ============================================

        stage('Update Infrastructure') {

            steps {

                sh '''
                    set -e

                    AMI_ID=$(cat backend-ami-id.txt)

                    echo "======================================="
                    echo "Using Backend AMI"
                    echo "$AMI_ID"
                    echo "======================================="

                    cd terraform

                    terraform init

                    terraform apply \
                      -auto-approve \
                      -var="backend_ami_id=$AMI_ID"
                '''
            }
        }

    }


    // ============================================
    // Post Actions
    // ============================================

    post {

        always {

            sh '''
                echo "Cleaning temporary Nexus settings file..."

                rm -f jenkins/settings.xml

                echo "Temporary Nexus settings file removed."
            '''
        }


        success {

            echo '''
=======================================
Pipeline executed successfully.
=======================================

Backend AMI created by Packer.
Launch Template updated.
ASG will launch backend instances
using the new AMI.
Frontend deployed to S3.
Nexus artifact deployment completed.

=======================================
'''
        }


        failure {

            echo '''
=======================================
Pipeline Failed.
Please check Jenkins Console Output.
=======================================
'''
        }
    }
}
