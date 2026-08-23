pipeline {

    agent any

    stages {

        stage('Checkout') {

            steps {

                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'
            }
        }


        stage('Enter Nexus Credentials') {

            steps {

                input(
                    message: '''

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


        
        stage('Configure Nexus Credentials') {

            steps {

                sh '''
                    set -e

                    echo "======================================="
                    echo "Fetching Nexus Credentials"
                    echo "======================================="


                    SECRET_JSON=$(aws secretsmanager get-secret-value \
                        --secret-id "server-inventory/nexus-credentials" \
                        --query SecretString \
                        --output text)


                    if [ -z "$SECRET_JSON" ] || [ "$SECRET_JSON" = "None" ]; then
                        echo "ERROR: Could not retrieve Nexus secret."
                        exit 1
                    fi


                    NEXUS_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
                    NEXUS_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')


                    if [ -z "$NEXUS_USERNAME" ] || [ "$NEXUS_USERNAME" = "null" ]; then
                        echo "ERROR: Nexus username was not found in Secrets Manager."
                        exit 1
                    fi


                    if [ -z "$NEXUS_PASSWORD" ] || [ "$NEXUS_PASSWORD" = "null" ]; then
                        echo "ERROR: Nexus password was not found in Secrets Manager."
                        exit 1
                    fi


                    echo "Generating Maven settings.xml..."


                    export nexus_username="$NEXUS_USERNAME"
                    export nexus_password="$NEXUS_PASSWORD"


                    envsubst < jenkins/settings.xml.tpl > jenkins/settings.xml


                    chmod 600 jenkins/settings.xml


                    echo "Creating Maven configuration directory if required..."


                    mkdir -p "$HOME/.m2"


                    echo "Copying settings.xml to Maven configuration directory..."


                    cp jenkins/settings.xml "$HOME/.m2/settings.xml"


                    chmod 600 "$HOME/.m2/settings.xml"


                    echo "Maven settings.xml configured successfully."


                    unset SECRET_JSON
                    unset NEXUS_USERNAME
                    unset NEXUS_PASSWORD
                    unset nexus_username
                    unset nexus_password
                '''
            }
        }


        stage('Build') {

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


        // ============================================================
        // Stage 2 - Build Backend AMI using Packer
        // ============================================================

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


                        echo "======================================="
                        echo "Validating Packer Configuration"
                        echo "======================================="


                        packer validate \
                          -var-file=terraform.pkrvars.hcl \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .


                        echo "======================================="
                        echo "Building Backend AMI"
                        echo "======================================="


                        packer build \
                          -var-file=terraform.pkrvars.hcl \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .


                        echo "======================================="
                        echo "Extracting AMI ID"
                        echo "======================================="


                        AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d: -f2)


                        if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "null" ]; then
                            echo "ERROR: AMI ID could not be extracted."
                            exit 1
                        fi


                        echo "Created AMI: $AMI_ID"


                        echo "$AMI_ID" > ../backend-ami-id.txt


                        echo "AMI ID saved to backend-ami-id.txt"
                    '''
                }
            }
        }


        // ============================================================
        // Stage 3 - Complete Remaining Infrastructure
        // ============================================================

        stage('Terraform - Update Infrastructure') {

            steps {

                dir('terraform') {

                    sh '''
                        set -e


                        AMI_ID=$(cat ../backend-ami-id.txt)


                        if [ -z "$AMI_ID" ]; then
                            echo "ERROR: Backend AMI ID is empty."
                            exit 1
                        fi


                        echo "======================================="
                        echo "Backend AMI"
                        echo "$AMI_ID"
                        echo "======================================="


                        echo "======================================="
                        echo "Terraform Init"
                        echo "======================================="


                        terraform init


                        echo "======================================="
                        echo "Terraform Validate"
                        echo "======================================="


                        terraform validate


                        echo "======================================="
                        echo "Terraform Plan"
                        echo "======================================="


                        terraform plan \
                          -var="backend_ami_id=$AMI_ID" \
                          -out=tfplan


                        echo "======================================="
                        echo "Creating/Updating Remaining Infrastructure"
                        echo "======================================="


                        terraform apply \
                          -auto-approve \
                          tfplan


                        echo "======================================="
                        echo "Terraform Apply Completed"
                        echo "======================================="
                    '''
                }
            }
        }

    }


    // ============================================================
    // Post Actions
    // ============================================================

    post {

        always {

            sh '''
                echo "======================================="
                echo "Cleaning Temporary Nexus Credentials"
                echo "======================================="


                rm -f jenkins/settings.xml
                rm -f "$HOME/.m2/settings.xml"
                rm -f terraform/tfplan


                echo "Temporary Nexus credential files removed."
            '''
        }


        success {

            echo '''
=======================================
Pipeline executed successfully.
=======================================


'''
        }


        failure {

            echo '''
=======================================
Pipeline Failed.
=======================================

'''
        }
    }
}
