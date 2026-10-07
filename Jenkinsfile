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

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "=== Connexion à Docker Hub ==="

                        echo "$DOCKERHUB_PASSWORD" | docker login \
                            -u "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        echo "=== Tag de l'image ==="

                        docker tag \
                            laravel-realworld-app:$BUILD_NUMBER \
                            $DOCKERHUB_USERNAME/laravel-realworld-app:$BUILD_NUMBER

                        echo "=== Push vers Docker Hub ==="

                        docker push \
                            $DOCKERHUB_USERNAME/laravel-realworld-app:$BUILD_NUMBER

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "=== Déploiement avec Docker Compose ==="

                        export IMAGE_TAG=$BUILD_NUMBER

                        echo "Username Docker Hub: $DOCKERHUB_USERNAME"
                        echo "Image déployée:"
                        echo "$DOCKERHUB_USERNAME/laravel-realworld-app:$IMAGE_TAG"

                        echo "=== Création du fichier .env ==="

                        cat > .env <<EOF
        APP_NAME=Laravel
        APP_ENV=production
        APP_KEY=base64:TA_CLE_ICI
        APP_DEBUG=false
        APP_URL=http://localhost:8000

        DB_CONNECTION=pgsql
        DB_HOST=db
        DB_PORT=5432
        DB_DATABASE=main
        DB_USERNAME=main
        DB_PASSWORD=main
        EOF

                        echo "=== Arrêt de l'ancienne version ==="
                        docker compose down

                        echo "=== Téléchargement des images ==="
                        docker compose pull

                        echo "=== Démarrage de l'application ==="
                        docker compose up -d

                        echo "=== Vérification ==="
                        docker compose ps
                    '''
                }
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