// dev branch -> abirami0901/dev ; master branch -> abirami0901/prod (+ deploy)
pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'abirami0901'
    DOCKERHUB      = credentials('dockerhub-creds')
    SERVER         = 'ubuntu@100.48.10.146'
    TARGET         = "${env.BRANCH_NAME == 'master' ? 'prod' : 'dev'}"
  }

  stages {
    stage('Build image') {
      steps { sh './build.sh ${TARGET}' }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          echo "$DOCKERHUB_PSW" | docker login -u "$DOCKERHUB_USR" --password-stdin
          docker push --all-tags ${DOCKERHUB_USER}/${TARGET}
        '''
      }
    }

    stage('Deploy to EC2') {
      when { branch 'master' }
      steps {
        sshagent(credentials: ['ec2-ssh-key']) {
          sh '''
            ssh -o StrictHostKeyChecking=no ${SERVER} "mkdir -p ~/app"
            scp -o StrictHostKeyChecking=no docker-compose.yml deploy.sh ${SERVER}:~/app/
            ssh -o StrictHostKeyChecking=no ${SERVER} "cd ~/app && chmod +x deploy.sh && DOCKERHUB_USER=${DOCKERHUB_USER} DOCKERHUB_TOKEN=${DOCKERHUB_PSW} ./deploy.sh prod"
          '''
        }
      }
    }
  }

  post {
    always { sh 'docker logout || true' }
  }
}
