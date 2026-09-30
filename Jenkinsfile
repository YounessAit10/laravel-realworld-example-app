pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    echo "=== Pipeline Jenkins démarré ==="
                    git --version
                    docker --version
                    docker compose version
                    ls -la
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline réussi ✅'
        }

        failure {
            echo 'Pipeline échoué ❌'
        }
    }
}