pipeline {

    agent any

    stages {

        // ============================================================
        // Checkout
        // ============================================================

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'
            }
        }


        // ============================================================
        // Terraform Format and Validate
        // ============================================================

        stage('Terraform Format and Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform fmt -recursive
                        terraform init -input=false
                        terraform validate
                    '''
                }
            }
        }


        // ============================================================
        // Terraform - SonarQube Infrastructure
        // ============================================================

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


        // ============================================================
        // Terraform - Nexus Infrastructure
        // ============================================================

        stage('Terraform - Nexus Infrastructure') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform apply \
                          -target=aws_security_group.nexus_sg \
                          -target=aws_vpc_security_group_ingress_rule.nexus_http \
                          -target=aws_vpc_security_group_ingress_rule.nexus_https \
                          -target=aws_vpc_security_group_ingress_rule.nexus_ssh \
                          -target=aws_vpc_security_group_ingress_rule.nexus_from_jenkins \
                          -target=aws_vpc_security_group_egress_rule.nexus_all_outbound \
                          -target=aws_iam_role.nexus_role \
                          -target=aws_iam_role_policy_attachment.nexus_ssm \
                          -target=aws_iam_instance_profile.nexus_profile \
                          -target=aws_instance.nexus \
                          -auto-approve
                    '''
                }
            }
        }


        // ============================================================
        // Terraform - RDS Infrastructure
        //
        // RDS is created BEFORE application build/deployment.
        // Terraform waits until the RDS instance becomes available.
        // ============================================================

        stage('Terraform - RDS Infrastructure') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        echo "======================================="
                        echo "Creating RDS PostgreSQL Infrastructure"
                        echo "======================================="

                        terraform apply \
                          -target=aws_db_subnet_group.db_subnet_group \
                          -target=aws_security_group.rds_sg \
                          -target=aws_vpc_security_group_ingress_rule.rds_from_backend \
                          -target=aws_vpc_security_group_egress_rule.rds_all_outbound \
                          -target=aws_db_instance.postgres \
                          -auto-approve

                        echo "======================================="
                        echo "RDS Infrastructure Created"
                        echo "======================================="

                        echo "RDS Endpoint:"
                        terraform output -raw rds_endpoint

                        echo "RDS Database Name:"
                        terraform output -raw rds_database_name

                        echo "======================================="
                        echo "RDS is now available"
                        echo "======================================="
                    '''
                }
            }
        }


        // ============================================================
        // Generate Maven POM
        // ============================================================

        stage('Generate Maven POM') {
            steps {
                dir('terraform') {
                    sh '''
                        set -e

                        terraform apply \
                          -target=local_file.backend_pom \
                          -auto-approve

                        if [ ! -f ../backend/pom.xml ]; then
                            echo "ERROR: backend/pom.xml was not generated."
                            exit 1
                        fi

                        echo "Maven pom.xml generated successfully."

                        ls -l ../backend/pom.xml
                    '''
                }
            }
        }


        // ============================================================
        // Wait for SonarQube
        // ============================================================

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
                            echo "http://$SONAR_IP:9000" > sonar-url.txt
                            exit 0
                        fi

                        sleep 10

                    done

                    echo "ERROR: SonarQube did not become ready."
                    exit 1
                '''
            }
        }


        // ============================================================
        // Configure SonarQube in Jenkins
        // ============================================================

        stage('Configure SonarQube in Jenkins') {
            steps {
                script {

                    def sonarUrl = sh(
                        script: 'cat sonar-url.txt',
                        returnStdout: true
                    ).trim()

                    input(
                        message: """
SonarQube Jenkins Configuration Required

SonarQube is now running successfully.

Configure SonarQube in Jenkins:

1. Go to:
   Manage Jenkins → System

2. Find:
   SonarQube servers

3. Add/configure a SonarQube server with:

   Name:
   sonarqube-server

   Server URL:
   ${sonarUrl}

4. Save the Jenkins configuration.

5. Return to this pipeline.

6. Click Proceed.
""",
                        ok: 'SonarQube Configured - Continue'
                    )
                }
            }
        }


        // ============================================================
        // Build and Test
        // ============================================================

        stage('Build and Test') {
            steps {
                dir('backend') {
                    sh '''
                        set -e

                        test -f pom.xml

                        mvn clean test
                    '''
                }
            }
        }


        // ============================================================
        // SonarQube Analysis
        // ============================================================

        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('sonarqube-server') {
                        sh '''
                            set -e

                            test -f pom.xml

                            mvn sonar:sonar
                        '''
                    }
                }
            }
        }


        // ============================================================
        // Quality Gate
        // ============================================================

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }


        // ============================================================
        // Terraform - Base Infrastructure
        //
        // IMPORTANT:
        // Packer outbound default rule is NOT targeted here because
        // AWS Security Groups already provide the default outbound
        // allow-all rule.
        // ============================================================

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
                          -target=aws_vpc_security_group_ingress_rule.packer_ssh_from_jenkins \
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
                          -auto-approve
                    '''
                }
            }
        }


        // ============================================================
        // Configure Nexus Repository
        // ============================================================

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


        // ============================================================
        // Enter Nexus Credentials
        // ============================================================

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


        // ============================================================
        // Configure Nexus Credentials
        // ============================================================

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


        // ============================================================
        // Deploy to Nexus
        // ============================================================

        stage('Deploy to Nexus') {
            steps {
                dir('backend') {
                    sh '''
                        set -e

                        test -f pom.xml

                        mvn deploy
                    '''
                }
            }
        }


        // ============================================================
        // Get Terraform Outputs Required by Packer
        // ============================================================

        stage('Get Packer Infrastructure IDs') {
            steps {
                sh '''
                    set -e

                    echo "======================================="
                    echo "Getting Terraform Outputs for Packer"
                    echo "======================================="

                    cd terraform

                    terraform init -input=false

                    SUBNET_ID=$(terraform output -raw public_subnet_1_id)

                    SECURITY_GROUP_ID=$(terraform output -raw packer_security_group_id)

                    BACKEND_INSTANCE_PROFILE=$(terraform output -raw backend_instance_profile)

                    if [ -z "$SUBNET_ID" ]; then
                        echo "ERROR: Public subnet ID is empty."
                        exit 1
                    fi

                    if [ -z "$SECURITY_GROUP_ID" ]; then
                        echo "ERROR: Packer security group ID is empty."
                        exit 1
                    fi

                    if [ -z "$BACKEND_INSTANCE_PROFILE" ]; then
                        echo "ERROR: Backend instance profile is empty."
                        exit 1
                    fi

                    cd ..

                    echo "$SUBNET_ID" > packer-subnet-id.txt

                    echo "$SECURITY_GROUP_ID" > packer-sg-id.txt

                    echo "$BACKEND_INSTANCE_PROFILE" > backend-instance-profile.txt

                    echo "Terraform outputs successfully retrieved."
                '''
            }
        }


        // ============================================================
        // DEBUG - Build Backend AMI
        //
        // IMPORTANT DEBUG MODE
        //
        // If ANY Packer provisioner fails, especially the Actuator
        // health check, Packer will ABORT without cleaning up the
        // source EC2 instance.
        //
        // This allows us to SSH/SSM into the exact failed instance
        // and investigate the real problem.
        //
        // DO NOT use this Jenkinsfile1 as the final production
        // pipeline.
        // ============================================================

        stage('DEBUG - Build Backend AMI') {
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
                        echo "DEBUG MODE - Initializing Packer"
                        echo "======================================="

                        cd packer

                        packer init .


                        echo "======================================="
                        echo "Reading Terraform Outputs"
                        echo "======================================="

                        SUBNET_ID=$(cat ../packer-subnet-id.txt)

                        SECURITY_GROUP_ID=$(cat ../packer-sg-id.txt)

                        BACKEND_INSTANCE_PROFILE=$(cat ../backend-instance-profile.txt)


                        if [ -z "$SUBNET_ID" ]; then
                            echo "ERROR: Subnet ID is empty."
                            exit 1
                        fi

                        if [ -z "$SECURITY_GROUP_ID" ]; then
                            echo "ERROR: Security Group ID is empty."
                            exit 1
                        fi

                        if [ -z "$BACKEND_INSTANCE_PROFILE" ]; then
                            echo "ERROR: Backend Instance Profile is empty."
                            exit 1
                        fi


                        echo "======================================="
                        echo "Validating Packer"
                        echo "======================================="

                        packer validate \
                          -var-file=terraform.pkrvars.hcl \
                          -var "subnet_id=$SUBNET_ID" \
                          -var "security_group_id=$SECURITY_GROUP_ID" \
                          -var "backend_instance_profile_name=$BACKEND_INSTANCE_PROFILE" \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .


                        echo "======================================="
                        echo "DEBUG MODE - Building Backend AMI"
                        echo "======================================="

                        echo ""
                        echo "IMPORTANT:"
                        echo "If the application/Actuator health check fails,"
                        echo "Packer will leave the source EC2 instance running."
                        echo ""
                        echo "DO NOT terminate the instance manually."
                        echo "Use SSH or SSM to investigate it."
                        echo ""

                        packer build \
                          -on-error=abort \
                          -var-file=terraform.pkrvars.hcl \
                          -var "subnet_id=$SUBNET_ID" \
                          -var "security_group_id=$SECURITY_GROUP_ID" \
                          -var "backend_instance_profile_name=$BACKEND_INSTANCE_PROFILE" \
                          -var "ssh_private_key_file=$PACKER_SSH_KEY" \
                          .


                        echo "======================================="
                        echo "Packer Build Completed"
                        echo "======================================="

                        echo ""
                        echo "The health check passed and Packer completed."
                        echo "This DEBUG pipeline does not continue to"
                        echo "Terraform - Update Infrastructure."
                        echo ""

                        exit 0
                    '''
                }
            }
        }


        // ============================================================
        // STOP HERE
        //
        // There is intentionally NO:
        //
        // Terraform - Update Infrastructure
        //
        // stage in Jenkinsfile1.
        //
        // This debugging pipeline ends after Packer.
        // ============================================================

        stage('DEBUG - STOP HERE') {
            steps {
                echo '''
============================================================
DEBUG PIPELINE STOPPED
============================================================

No Terraform infrastructure update will be performed.

If the Packer health check failed:
  - The source Packer EC2 instance should remain available
    because Packer was executed with -on-error=abort.
  - SSH/SSM into that instance.
  - Check Tomcat.
  - Check the deployed WAR.
  - Check Spring Boot logs.
  - Check Actuator endpoints.
  - Check database connectivity.
  - Check environment variables.
  - Check the exact health-check URL.

Find the REAL root cause before modifying the pipeline.

============================================================
'''
            }
        }
    }


    // ================================================================
    // Post Actions
    // ================================================================

    post {

        always {
            sh '''
                rm -f jenkins/settings.xml
                rm -f "$HOME/.m2/settings.xml"
                rm -f terraform/tfplan
                rm -f backend-ami-id.txt
                rm -f sonar-url.txt
                rm -f packer-subnet-id.txt
                rm -f packer-sg-id.txt
                rm -f backend-instance-profile.txt
            '''
        }

        success {
            echo 'DEBUG pipeline completed successfully and intentionally stopped.'
        }

        failure {
            echo '''
============================================================
DEBUG PIPELINE FAILED
============================================================

If failure occurred during Packer provisioning:

The Packer build was executed with:

    -on-error=abort

Therefore, the source EC2 instance should remain available
for investigation.

Do NOT terminate it yet.

Use SSH or SSM to investigate the actual failure.

============================================================
'''
        }
    }
}
