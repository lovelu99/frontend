pipeline {
    agent any
    environment {
            GITOPS_DIR = 'gitops-repo'
            IMAGE_NAME       = "noakhali/todo-frontend"
            IMAGE_TAG  = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()                       
    }
    stages {
        stage('Checkout')  {
            steps{
                echo 'Checking out git main branch'
                git branch: 'main', url:'https://github.com/lovelu99/frontend.git'
            }
        }
        stage ('Build Docker Images'){
            steps {
                sh """
                echo 'Building docker image'
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }
        stage  ('Container Security Scan'){
            steps {
                script {
                    sh 'echo "Running Trivy scan on the Docker image"'
                    sh 'mkdir -p reports'
                    def trivyStatus = sh (
                    script: """
                    trivy image ${IMAGE_NAME}:${IMAGE_TAG} \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --ignore-unfixed \
                    --format table \
                    --output reports/trivy-report.txt \
                    --no-progress
                    """,
                    returnStatus: true
                    )
                    // archive report regardless of scan result
                    archiveArtifacts artifacts: 'reports/*', fingerprint: true, allowEmptyArchive: true

                    // fail pipeline if vulnerabilities detected
                    if (trivyStatus != 0) {
                        error("Trivy detected HIGH/CRITICAL vulnerabilities. See the report in Jenkins artifacts.")
                    }
                }
            }
        }
        stage ('Code Quality Scan') {
            steps {
                script {
                    def scannerHome = tool 'sonarscanner'
                    withSonarQubeEnv('sonarqube') {                   
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=todo-frontend \
                        -Dsonar.projectName=todo-frontend \
                        -Dsonar.sources=. \
                        -Dsonar.token=${env.SONAR_AUTH_TOKEN}
                    """
                    }
                    timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                    }
                }                
            }
        }
        stage ('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                sh """
                echo 'Pushing Docker Image'
                echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """  
                }
            }
        }
        stage ('Deploy') {
            steps {
                build job: 'config-repo',
                parameters: [
                    string(name: 'IMAGE_NAME', value: "${IMAGE_NAME}"),
                    string(name: 'IMAGE_TAG', value: "${IMAGE_TAG}")
                    
                ]
            }
        }
        stage('Cleaning Workspace') {
            steps {
                script{
                    sh """
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                    cleanWs()
                }
            }
        }
    }
}