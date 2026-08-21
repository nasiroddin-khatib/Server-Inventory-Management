pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/nasiroddin-khatib/Server-Inventory-Management.git'
            }
        }


        stage('Build') {
            steps {
                dir('backend') {
                    sh 'mvn clean compile'
                }
            }
        }


        stage('Test') {
            steps {
                dir('backend') {
                    sh 'mvn test'
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

                    sh 'mvn deploy -s /var/jenkins_home/.m2/settings.xml'

                }
            }
        }


        stage('Deploy Frontend to S3') {
            steps {

                sh '''
                    aws s3 sync frontend/ s3://mybkt-575458732395-ap-south-1-an --delete
                '''

            }
        }


        ############################################
        # Packer
        ############################################

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
                        echo "Validating Packer"
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
                        echo "Reading AMI ID"
                        echo "======================================="

                        AMI_ID=$(jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d: -f2)

                        echo "Created AMI: $AMI_ID"

                        echo "$AMI_ID" > ../backend-ami-id.txt
                    '''
                }
            }
        }


        ############################################
        # Terraform
        ############################################

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


    post {

        success {

            echo '''
            =======================================
            Pipeline executed successfully.
            Backend AMI created by Packer.
            Launch Template updated.
            ASG will launch backend instances
            using the new AMI.
            Frontend deployed to S3.
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
