pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID="<YOUR_AWS_ACCOUNT_ID>"
        AWS_DEFAULT_REGION="us-east-1" 
        IMAGE_REPO_NAME="finsync-repo"
        IMAGE_TAG="latest"
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
    }
    
    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/<YOUR_GITHUB_USER>/finsync-payment-service.git'
            }
        }
        
        stage('Build & Test') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Static Code Analysis (SonarQube)') {
            steps {
                withSonarQubeEnv('SonarCloud') { // Configure this name in Jenkins System settings
                   sh 'mvn sonar:sonar -Dsonar.organization=<YOUR_SONAR_ORG> -Dsonar.projectKey=<YOUR_PROJECT_KEY> -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=$SONAR_AUTH_TOKEN'
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                sh 'trivy fs . --format table -o trivy-report.txt'
                archiveArtifacts artifacts: 'trivy-report.txt', fingerprint: true
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${IMAGE_TAG}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    dockerImage.push()
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                    aws eks update-kubeconfig --region us-east-1 --name finsync-cluster
                    kubectl apply -f deployment.yaml
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Notification logic here
            echo 'Pipeline finished. Sending notification...'
            // slackSend channel: '#devops', color: 'good', message: "Job ${env.JOB_NAME} completed."
        }
        success {
            echo 'Deployment Successful!'
        }
        failure {
            echo 'Deployment Failed.'
        }
    }
}
