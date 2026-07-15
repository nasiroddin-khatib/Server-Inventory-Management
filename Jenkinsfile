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
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube-server') {
                    sh 'mvn sonar:sonar'
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
                sh 'mvn clean package'
            }
        }

        stage('Deploy to Nexus') {
            steps {
                sh 'mvn deploy'
            }
        }

        stage('Deploy Frontend to S3') {
            steps {
                sh '''
                    aws s3 sync frontend/ s3://mybkt-575458732395-ap-south-1-an \
                        --delete
                '''
            }
        }

        stage('Deploy Backend using Ansible') {
            steps {
                ansiblePlaybook(
                    credentialsId: 'tomcat',
                    disableHostKeyChecking: true,
                    installation: 'ansible',
                    inventory: 'ansible/hosts',
                    playbook: 'ansible/deploy.yml'
                )
            }
        }

    }

    post {

        success {
            echo '======================================='
            echo 'Pipeline executed successfully.'
            echo 'Backend deployed to Tomcat.'
            echo 'Frontend deployed to Amazon S3.'
            echo '======================================='
        }

        failure {
            echo '======================================='
            echo 'Pipeline Failed.'
            echo 'Please check Jenkins Console Output.'
            echo '======================================='
        }
    }
}
