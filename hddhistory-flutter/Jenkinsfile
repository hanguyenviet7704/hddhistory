pipeline {
    agent any

    environment {
        GIT_COMMIT_ID = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
    }

    stages {
        stage('SonarQube Flutter Analysis') {
            steps {
                script {
                    def shortCommit = env.GIT_COMMIT.take(6)

                    // Tạo sonar-project.properties cho Flutter/Dart
                    sh """
                        echo sonar.projectKey=${env.JOB_NAME} > sonar-project.properties
                        echo sonar.projectName=${env.JOB_NAME} >> sonar-project.properties
                        echo sonar.projectVersion=${shortCommit} >> sonar-project.properties

                        # Chỉ định thư mục source chính của Flutter là lib
                        echo sonar.sources=lib >> sonar-project.properties

                        # Nếu có thư mục test, chỉ định vị trí các file test
                        echo #sonar.tests=test >> sonar-project.properties
                        echo #sonar.test.inclusions=test/**/*.dart >> sonar-project.properties

                        # Loại trừ các thư mục không cần quét
                        echo sonar.exclusions=build/**,.dart_tool/**,**/*.g.dart >> sonar-project.properties
                    """

                    def scannerHome = tool 'sonar-scan'
                    withSonarQubeEnv('sonar-jenkins') {
                        sh """
                            # Cấu hình môi trường Java
                            export JAVA_HOME=/usr/local/jdk-17.0.8+7
                            export PATH=\${JAVA_HOME}/bin:\$PATH

                            # Cấu hình Sonar Scanner
                            export SONAR_SCANNER_OPTS="-Xmx2048m"

                            echo "Starting SonarQube Analysis for Flutter source code..."
                            ${scannerHome}/bin/sonar-scanner
                        """
                    }
                }
            }
        }
    }
}
