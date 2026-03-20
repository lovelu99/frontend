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
            steps{
                sh """
                echo ' Security scan'
                """
            }
        }
        stage ('Code Quality Scan') {
            steps{
                sh """
                echo 'Code quality scan'                    
                """

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
                    string(name: 'IMAGE_NAME', value:${IMAGE_NAME}),
                    string(name: 'IMAGE_TAG', value:${IMAGE_TAG})
                    
                ]
            }
        }
        stage('Cleaning Workspace') {
            steps {
                script{
                    sh """
                    dodocker rmi ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                    cleanWs()
                }
            }
        }
    }
}