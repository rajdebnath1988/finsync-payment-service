pipeline {
    agent any
    
    environment {
        AWS_ACCOUNT_ID="279606006025"
        AWS_DEFAULT_REGION="us-east-1"
        IMAGE_REPO_NAME="finsync-repo"
        IMAGE_TAG="latest"
        ECR_REGISTRY="279606006025.dkr.ecr.us-east-1.amazonaws.com"
    }
    
    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rajdebnath1988/finsync-payment-service.git'
            }
        }
        
        stage('Build & Test') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Static Code Analysis (SonarQube)') {
            environment {
                SONAR_AUTH_TOKEN = credentials('sonar-token') 
            }
            steps {
                withSonarQubeEnv('SonarCloud') { 
                    // FIXED COMMAND BELOW
                    sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.organization=rajdebnath1988 -Dsonar.projectKey=rajdebnath1988_finsync-payment-service -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=$SONAR_AUTH_TOKEN'
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
                    dockerImage = docker.build("${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    script {
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    script {
                        sh """
                        aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name finsync-cluster
                        sed -i 's|image: .*|image: ${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${env.BUILD_NUMBER}|' deployment.yaml
                        kubectl apply -f deployment.yaml
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline finished.'
        }
        success {
            echo 'Deployment Successful!'
        }
        failure {
            echo 'Deployment Failed.'
        }
    }
}
