pipeline {
    agent any

    stages {
        
        stage('Determine Target') {
            steps {
                script {
                    env.GIT_COMMIT_ID = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.GIT_TAG_NAME = sh(script: 'git describe --exact-match --tags $(git rev-parse HEAD) || true', returnStdout: true).trim()
                    def branchOutput = sh(script: 'git branch -r --contains HEAD || true', returnStdout: true).trim()

                    if (env.GIT_TAG_NAME && branchOutput.contains("origin/main")) {
                        env.TARGET = 'production'
                    } else if (env.GIT_BRANCH == 'origin/develop') {
                        env.TARGET = 'develop'
                    } else {
                        error("Only 'develop' branch or tag on 'main' are allowed to trigger build.")
                    }
                }
            }
        }

        stage('Build dev') {
            when {
                expression { env.TARGET == 'develop' }
            }
            steps {
                timeout(time: 40, unit: 'MINUTES') {
                    echo "Building for develop branch"
                    sshagent(['gitlab-ssh-key']) {
                       sh """ssh -o StrictHostKeyChecking=no ansible@188.166.208.109 << EOF
                            cd /home/ansible/resource/meup/admin-dev/
                            git checkout develop
                            git pull origin develop
                            docker build -t registry.gitlab.com/eup/meup/meup-admin:${env.GIT_COMMIT_ID} .
                            docker push registry.gitlab.com/eup/meup/meup-admin:${env.GIT_COMMIT_ID}
                            docker rmi registry.gitlab.com/eup/meup/meup-admin:${env.GIT_COMMIT_ID}
                            exit
                        EOF"""
                    }
                }
            }
        }

        stage('Deploy dev') {
            when {
                expression { env.TARGET == 'develop' }
            }
            steps {
                echo "Deploying to develop environment"
                sshagent(['gitlab-ssh-key']) {
                    sh """ssh -o StrictHostKeyChecking=no ansible@192.168.10.137 << EOF
                            kubectl config use-context k8s-local-dev
                            kubectl set image deployment/admin admin=registry.gitlab.com/eup/meup/meup-admin:${env.GIT_COMMIT_ID} -n meup-dev
                            kubectl config use-context k8s-local-dev
                            kubectl rollout status deployment/admin -n meup-dev
                            exit
                        EOF"""
                }
            }
        }


        stage('Build production') {
            when {
                expression { env.TARGET == 'production' }
            }
            steps {
                timeout(time: 40, unit: 'MINUTES') {
                    echo "Building for production with tag: ${env.GIT_TAG_NAME}"
                    sshagent(['gitlab-ssh-key']) {
                       sh """ssh -o StrictHostKeyChecking=no ansible@188.166.208.109 << EOF
                            cd /home/ansible/resource/meup/admin-prod/
                            git fetch --all --tags
                            git checkout tags/${env.GIT_TAG_NAME}
                            docker build -t registry.gitlab.com/eup/meup/meup-admin:${env.GIT_TAG_NAME} .
                            docker push registry.gitlab.com/eup/meup/meup-admin:${env.GIT_TAG_NAME}
                            docker rmi registry.gitlab.com/eup/meup/meup-admin:${env.GIT_TAG_NAME}
                            exit
                        EOF"""
                    }
                }
            }
        }

        stage('Deploy production') {
            when {
                expression { env.TARGET == 'production' }
            }
            steps {
                echo "Deploying to production environment"
                sshagent(['gitlab-ssh-key']) {
                    sh """ssh -o StrictHostKeyChecking=no ansible@192.168.10.137 << EOF
                            kubectl config use-context do-sgp1-k8s-all-project
                            kubectl set image deployment/admin \
                                    admin=registry.gitlab.com/eup/meup/meup-admin:${env.GIT_TAG_NAME} \
                                    -n meup
                            kubectl config use-context do-sgp1-k8s-all-project
                            kubectl rollout status deployment/admin -n meup
                            exit
                        EOF"""
                }
            }
        }
    }
}
