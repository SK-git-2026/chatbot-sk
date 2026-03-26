pipeline {

    agent any

    environment {
        DOCKER_REPO = "skpatilhub/chatbot-sk-app"
        VERSION = "${BUILD_NUMBER}"
        AWS_REGION = "us-east-1"
        CLUSTURE_NAME = "sk-cluster"
        NAME_SPACE = "sk"
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

        stage ("Clustrt update"){
            steps{
                sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}"
            }
        }

        stage ('Deployment'){
            steps{  withKubeConfig(caCertificate: '', clusterName: 'sk-cluster', contextName: '', credentialsId: 'token', namespace: 'sk', restrictKubeConfigAccess: false, serverUrl: 'https://0E4D068285505D2D4422706BA430F8C2.yl4.us-east-1.eks.amazonaws.com') {
    // some block
                sh "kubectl apply -f Deployment.yml -n ${NAMESPACE}" 
                sh "kubectl get pods -n ${NAMESPACE}"
                sh "kubectl get svc -n ${NAMESPACE}"
             }

            }
        }

    }
}