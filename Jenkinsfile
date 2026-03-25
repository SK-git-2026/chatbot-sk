pipeline {

    agent any

    environment {
        DOCKER_REPO = "skpatilhub/chatbot-sk-app"
        VERSION = "${BUILD_NUMBER}"
    }

    stages {

        stage('Git Checkout') {
            steps {
                git url: 'https://github.com/SK-git-2026/chatbot-sk.git', branch: 'main'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_REPO}:${VERSION} ."
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                }
            }
        }

        stage('Push Image') {
            steps {
                sh "docker push ${DOCKER_REPO}:${VERSION}"
            }
        }

    }
}