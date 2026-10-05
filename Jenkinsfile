pipeline {
    agent any

    environment {
        image_name = "rgneswar/demohello"
    }

    stages {
        stage("git-checkout") {
            steps {
                checkout scm
            }
        }
        stage("image-build") {
            steps {
                script {
                    env.image_tag = new Date().format("yyyy-MM-dd-HHmmss")
                    env.full_image = "${env.image_name}:${env.image_tag}"
                }
            }
        }
        stage("docker login") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker_cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                    }
                }
            }
        }
        stage("docker push") {
            steps {
                script {
                    sh "docker build -t ${env.full_image} ."
                    sh "docker push ${env.full_image}"
                }
            }
        }
    }
}