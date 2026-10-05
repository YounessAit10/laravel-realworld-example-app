pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('GitLeaks') {
            steps {
                sh '''
                    echo "=== Scan GitLeaks ==="

                    docker run --rm \
                        --volumes-from jenkins \
                        -w "$WORKSPACE" \
                        zricethezav/gitleaks:latest \
                        git --verbose --redact .
                '''
            }
        }

        stage('PHP Tests') {
            steps {
                sh '''
                    echo "=== Build image de test ==="

                    docker build \
                        -f Dockerfile.test \
                        -t laravel-test:$BUILD_NUMBER \
                        .

                    echo "=== Lancement tests PHP ==="

                    docker run --rm \
                        --network laravel-realworld-example-app_default \
                        -e APP_ENV=testing \
                        -e DB_CONNECTION=pgsql \
                        -e DB_HOST=db_test \
                        -e DB_PORT=5432 \
                        -e DB_DATABASE=main \
                        -e DB_USERNAME=main \
                        -e DB_PASSWORD=main \
                        laravel-test:$BUILD_NUMBER
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Production Image') {
            steps {
                sh '''
                    echo "=== Build image de production ==="

                    docker build \
                        -t laravel-realworld-app:$BUILD_NUMBER \
                        .
                '''
            }
        }

        stage('Check Docker Image') {
            steps {
                sh '''
                    echo "=== Images Docker disponibles ==="
                    docker images
                    echo "=== Vérification de l'image ==="
                    docker image inspect laravel-realworld-app:$BUILD_NUMBER
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    echo "=== Scan de sécurité avec Trivy ==="

                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:latest \
                        image \
                        --timeout 15m \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        laravel-realworld-app:$BUILD_NUMBER
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    echo "=== Vérification environnement ==="
                    git --version
                    docker --version
                    docker compose version
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