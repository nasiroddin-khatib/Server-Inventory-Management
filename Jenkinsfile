pipeline {

    agent any

    tools {
        maven 'maven'
    }

    environment {

        AWS_CREDENTIALS = 'aws-creds'
        SONARQUBE_SERVER = 'sonarqube-server'
        NEXUS_CREDENTIALS = 'nexus-creds'
        

        AWS_DEFAULT_REGION = 'ap-south-1'

        TF_DIR = 'terraform'
        PACKER_DIR = 'packer'
        BACKEND_DIR = 'backend'
        FRONTEND_DIR = 'frontend'

        PACKER_VARS_FILE = 'packer.auto.pkrvars.hcl'

        FRONTEND_BUCKET = 'server-inventory-frontend-3819'
    }

    stages {

        stage('Checkout') {

            steps {

                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'

            }

        }

        stage('Terraform Init') {

            steps {

                dir("${TF_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {

                        sh '''
                        terraform init
                        terraform validate
                        '''

                    }

                }

            }

        }

        stage('Terraform Bootstrap') {

            steps {

                dir("${TF_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {

                        sh '''
terraform apply \
-target=aws_vpc.vpc \
-target=aws_internet_gateway.igw \
-target=aws_subnet.public_subnet_1 \
-target=aws_subnet.public_subnet_2 \
-target=aws_subnet.private_subnet_1 \
-target=aws_subnet.private_subnet_2 \
-target=aws_eip.nat_eip \
-target=aws_nat_gateway.nat_gateway \
-target=aws_route_table.public_route_table \
-target=aws_route_table.private_route_table \
-target=aws_route_table_association.public_subnet_1 \
-target=aws_route_table_association.public_subnet_2 \
-target=aws_route_table_association.private_subnet_1 \
-target=aws_route_table_association.private_subnet_2 \
-target=aws_security_group.alb_sg \
-target=aws_security_group.backend_sg \
-target=aws_security_group.rds_sg \
-target=aws_security_group.jenkins_sg \
-target=aws_security_group.sonarqube_sg \
-target=aws_security_group.nexus_sg \
-target=aws_security_group.monitoring_sg \
-target=aws_iam_role.backend_role \
-target=aws_iam_role_policy_attachment.backend_ssm \
-target=aws_iam_role_policy_attachment.backend_cloudwatch \
-target=aws_iam_instance_profile.backend_instance_profile \
-target=aws_secretsmanager_secret.database_secret \
-target=aws_secretsmanager_secret_version.database_secret_value \
-target=aws_db_subnet_group.db_subnet_group \
-target=aws_db_instance.postgres \
-target=aws_s3_bucket.frontend \
-target=aws_s3_bucket_versioning.frontend \
-target=aws_s3_bucket_server_side_encryption_configuration.frontend \
-target=aws_s3_bucket_ownership_controls.frontend \
-target=aws_s3_bucket_public_access_block.frontend \
-target=aws_s3_bucket_policy.frontend \
-auto-approve
'''
                    }

                }

            }

        }

        stage('Build') {

            steps {

                dir("${BACKEND_DIR}") {

                    sh 'mvn clean compile'

                }

            }

        }

        stage('Test') {

            steps {

                dir("${BACKEND_DIR}") {

                    sh 'mvn test'

                }

            }

        }

        stage('SonarQube Analysis') {

            steps {

                dir("${BACKEND_DIR}") {

                    withSonarQubeEnv("${SONARQUBE_SERVER}") {

                        sh '''
                        mvn sonar:sonar
                        '''

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

                dir("${BACKEND_DIR}") {

                    sh '''
                    mvn clean package
                    '''

                }

            }

        }

        stage('Deploy To Nexus') {

            steps {

                dir("${BACKEND_DIR}") {

                    withCredentials([

                        usernamePassword(
                            credentialsId: "${NEXUS_CREDENTIALS}",
                            usernameVariable: 'NEXUS_USERNAME',
                            passwordVariable: 'NEXUS_PASSWORD'
                        )

                    ]) {

                        sh '''
                        mvn deploy \
                        -Dnexus.username=$NEXUS_USERNAME \
                        -Dnexus.password=$NEXUS_PASSWORD
                        '''

                    }

                }

            }

        }

        stage('Read Terraform Outputs') {

            steps {

                dir("${TF_DIR}") {

                    script {

                        AMI_NAME = sh(
                            script: "terraform output -raw ami_name",
                            returnStdout: true
                        ).trim()

                    }

                }

            }

        }

        stage('Packer Init') {

            steps {

                dir("${PACKER_DIR}") {

                    withCredentials([

                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]

                    ]) {

                        sh '''
                        packer init .
                        '''

                    }

                }

            }

        }

        stage('Packer Validate') {

            steps {

                dir("${PACKER_DIR}") {

                    withCredentials([

                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]

                    ]) {

                        sh '''
                        packer validate \
                        -var-file=${PACKER_VARS_FILE} \
                        .
                        '''

                    }

                }

            }

        }

        stage('Packer Build') {

            steps {

                dir("${PACKER_DIR}") {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: "${AWS_CREDENTIALS}"],

                    usernamePassword(
                        credentialsId: "${NEXUS_CREDENTIALS}",
                        usernameVariable: 'NEXUS_USERNAME',
                        passwordVariable: 'NEXUS_PASSWORD'
    )
])  {

                        sh '''
                        packer build \
                        -var ami_name=$AMI_NAME \
                        -var-file=${PACKER_VARS_FILE} \
                        -var nexus_username=$NEXUS_USERNAME \
                        -var nexus_password=$NEXUS_PASSWORD \
                        .
                        '''

                    }

                }

            }

        }


        stage('Terraform Stage 2') {

            steps {

                dir("${TF_DIR}") {

                    withCredentials([

                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]

                    ]) {

                        sh '''
terraform apply \
-target=aws_lb.backend \
-target=aws_lb_target_group.backend \
-target=aws_lb_listener.backend_http \
-target=aws_ami.backend \
-target=aws_autoscaling_group.backend \
-target=aws_autoscaling_policy.scale_out \
-target=aws_cloudwatch_metric_alarm.cpu_high \
-auto-approve
'''

                    }

                }

            }

        }

        stage('Deploy Frontend To S3') {

            steps {

                withCredentials([

                    [$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS}"]

                ]) {

                    sh """

cd ${TF_DIR}
ALB=\$(terraform output -raw alb_dns_name)

cat > ../${FRONTEND_DIR}/config.js <<EOF
window.APP_CONFIG = {
    BASE_URL: "http://\${ALB}/server-inventory/api/servers"
};
EOF


aws s3 sync \
${FRONTEND_DIR}/ \
s3://${FRONTEND_BUCKET} \
--delete
"""

                }

            }

        }

        stage('Backend Health Check') {

            steps {

                script {

                    def ALB_DNS = sh(
                        script: """
cd ${TF_DIR}
terraform output -raw alb_dns_name
""",
                        returnStdout: true
                    ).trim()

                    sh """
curl \
--retry 20 \
--retry-delay 15 \
--fail \
http://${ALB_DNS}/server-inventory/actuator/health
"""

                }

            }

        }

        stage('Frontend Health Check') {

            steps {

                sh """
curl \
--retry 20 \
--retry-delay 10 \
--fail \
http://${FRONTEND_BUCKET}.s3-website.ap-south-1.amazonaws.com
"""

            }

        }

        stage('Deployment Summary') {

            steps {

                echo '==============================================='
                echo ' Infrastructure Provisioned Successfully'
                echo ' Golden AMI Created Successfully'
                echo ' Auto Scaling Group Updated'
                echo ' Backend Deployed Successfully'
                echo ' Frontend Uploaded Successfully'
                echo ' Health Checks Passed'
                echo '==============================================='

            }

        }

    post {

        success {

            echo '==============================================='
            echo ' PIPELINE COMPLETED SUCCESSFULLY'
            echo '==============================================='
            echo 'Terraform Bootstrap Completed'
            echo 'Application Built Successfully'
            echo 'Tests Passed'
            echo 'SonarQube Quality Gate Passed'
            echo 'Artifact Published To Nexus'
            echo 'Golden AMI Created Successfully'
            echo 'Infrastructure Updated Successfully'
            echo 'Frontend Deployed To S3'
            echo 'Backend Health Check Passed'
            echo 'Frontend Health Check Passed'
            echo '==============================================='

        }

        failure {

            echo '==============================================='
            echo ' PIPELINE FAILED'
            echo '==============================================='
            echo 'Check Jenkins Console Output'
            echo 'Terraform State'
            echo 'Packer Logs'
            echo 'SonarQube Logs'
            echo 'Maven Build Logs'
            echo '==============================================='

        }

        always {

            cleanWs()

        }

    }

}
        

        
