pipeline {
  agent any

  environment {
    REPO = 'OWNER/REPO'          // <-- change: github owner/repo
    CPU_LIMIT = '80'
    DISK_LIMIT = '80'
    TARGET_UBUNTU = '24.04'
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'rm -rf report && mkdir -p report'
      }
    }

    stage('Bash Syntax Check') {
      steps {
        sh '''#!/bin/bash
          set -eo pipefail
          bash scripts/syntax_check.sh 2>&1 | tee -a report/report.txt
        '''
      }
    }

    stage('CPU & Disk Health') {
      steps {
        sh '''#!/bin/bash
          set -eo pipefail
          bash scripts/health_check.sh 2>&1 | tee -a report/report.txt
        '''
      }
    }

    stage('Dockerfile Check') {
      steps {
        sh '''#!/bin/bash
          set -eo pipefail
          bash scripts/dockerfile_check.sh "test-image-${BUILD_NUMBER}" 2>&1 | tee -a report/report.txt
        '''
      }
    }

    // Only on main branch builds, and never for bot's own commits (loop avoid)
    stage('Update Dockerfile & Raise PR') {
      when {
        allOf {
          branch 'main'
          not { changeRequest() }
          expression {
            def msg = sh(script: 'git log -1 --pretty=%s', returnStdout: true).trim()
            return !msg.contains('[auto]')
          }
        }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-pat',
                                          usernameVariable: 'GH_USER',
                                          passwordVariable: 'GH_TOKEN')]) {
          sh 'bash scripts/auto_pr.sh'
        }
      }
    }
  }

  post {
    always {
      echo '========== FINAL REPORT =========='
      sh 'cat report/report.txt || true'
      archiveArtifacts artifacts: 'report/report.txt', allowEmptyArchive: true
    }
    success { echo 'All checks passed' }
    failure { echo 'Pipeline failed, check report above' }
    cleanup { sh 'docker rmi test-image-${BUILD_NUMBER} || true' }
  }
}
