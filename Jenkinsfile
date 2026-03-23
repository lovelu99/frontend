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
                    --scanners vuln \
                    --severity HIGH,CRITICAL \
                    --exit-code 1 \
                    --ignore-unfixed \
                    --format json \
                    --output reports/trivy-report.json \
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
            post {
                failure {
                    emailext(
                        subject: "Trivy Scan Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        mimeType: 'text/html',
                        body: """
                        <html>
                        <body>
                            <h2>Container Security Scan Failed</h2>
                            <p><b>Job Name:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                            <p><b>Stage:</b> Container Security Scan</p>
                            <p><b>Docker Image:</b> ${IMAGE_NAME}:${IMAGE_TAG}</p>
                            <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            <p>Trivy detected <b>HIGH/CRITICAL</b> vulnerabilities in the container image.</p>
                            <p>Please review the Jenkins console output and attached Trivy report.</p>
                        </body>
                        </html>
                        """,
                        to: 'relibot107@onbap.com',
                        attachmentsPattern: 'reports/trivy-report.json'
                    )
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
            post {
                failure {
                    emailext(
                        subject: "SonarQube Quality Gate Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        mimeType: 'text/html',
                        body: """
                        <html>
                        <body>
                            <h2>SonarQube Quality Gate Failed</h2>
                            <p><b>Job Name:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                            <p><b>Stage:</b> Quality Gate</p>
                            <p><b>Project:</b> ${env.JOB_NAME}</p>
                            <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                            <p>The SonarQube quality gate did not pass.</p>
                            <p>Please review code issues, bugs, vulnerabilities, code smells, coverage, and duplication in SonarQube before proceeding.</p>
                        </body>
                        </html>
                        """,
                        to: 'relibot107@onbap.com'
                    )
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
    post { 
        success { 
            emailext(
                subject: "Front end sucessfully Build and Deployed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
                <html>
                <body>
                    <h2>Front end sucessfully Build and Deployed</h2>
                    <p><b>Job Name:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Stage:</b> Quality Gate</p>
                    <p><b>Project:</b> ${env.JOB_NAME}</p>
                    <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                </body>
                </html>
                """,
                to: 'relibot107@onbap.com'
            )
        }
    }
}