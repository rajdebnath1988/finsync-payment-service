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
                // Ensure this ID matches your Jenkins Credential exactly (check for trailing dashes)
                SONAR_AUTH_TOKEN = credentials('sonar-token') 
            }
            steps {
                withSonarQubeEnv('SonarCloud') { 
                    sh 'mvn sonar:sonar -Dsonar.organization=rajdebnath1988 -Dsonar.projectKey=rajdebnath1988_finsync-payment-service -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=$SONAR_AUTH_TOKEN'
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
                    // Builds the image with the specific Jenkins Build Number (e.g., :5, :6)
                    dockerImage = docker.build("${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                // Wrapped in credentials to ensure permission, even if server keys are missing
                withCredentials([usernamePassword(credentialsId: 'aws-creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    script {
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                        dockerImage.push()           // Pushes version :5
                        dockerImage.push('latest')   // Pushes version :latest
                    }
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    script {
                        // CHANGED: Uses double quotes (""") so variables like ${AWS_DEFAULT_REGION} work
                        sh """
                        # 1. Login to Cluster
                        aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name finsync-cluster
                        
                        # 2. Update Image Version (Crucial Fix!)
                        # Replaces the old image in deployment.yaml with the new Build Number
                        sed -i 's|image: .*|image: ${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${env.BUILD_NUMBER}|' deployment.yaml
                        
                        # 3. Apply changes to Kubernetes
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
