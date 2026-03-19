pipeline{
    agent any

    environment {
        IMAGE_NAME = "chatbot-sk-app"
        VERSION = "${BUILD_NUMBER}"

    }

    stages{
        stage('Git Checkout')
        {
           steps{ 
            git url: 'https://github.com/SK-git-2026/chatbot-sk.git',branch: 'main'
           }

        }
        stage('Docker Build'){

            steps{
                sh''' docker build -t $IMAGE_NAME . '''                

            }
        }
        stage('Container run'){
            steps{
                sh'''
                docker stop sk-chatbot || true
                docker rm sk-chatbot || true
                docker run -it -d --name sk-chatbot -p 9001:8501 $IMAGE_NAME
                ''' 
            }
        }

    }
}