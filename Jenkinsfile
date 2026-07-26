pipeline {

    agent any

    environment {
        AWS_CREDENTIALS = 'aws-creds'
        TF_DIR = 'terraform'
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
                        mv terraform/launch-template.tf terraform/launch-template.tf.bak
                        terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS}"]
                    ]) {
                        sh '''
                        terraform destroy -auto-approve
                        '''
                    }
                }
            }
        }

    }

    post {

        success {
            echo "======================================"
            echo "Infrastructure Destroyed Successfully"
            echo "======================================"
        }

        failure {
            echo "======================================"
            echo "Terraform Destroy Failed"
            echo "======================================"
        }

    }
}
