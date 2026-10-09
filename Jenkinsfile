pipeline {
  agent any

  environment {
    REPO = 'Rajesh33-11/miniproject-'
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

    // Feature branch push build only (not main, not PR build, not bot's own commit)
    stage('Update Dockerfile & Raise PR') {
      when {
        allOf {
          not { branch 'main' }
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
    // PR build only: all checks above passed -> enable auto-merge on this PR
    stage('Enable Auto-Merge') {
      when { changeRequest() }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-pat',
                                          usernameVariable: 'GH_USER',
                                          passwordVariable: 'GH_TOKEN')]) {
          sh 'gh pr merge "$CHANGE_ID" --repo "$REPO" --auto --squash --delete-branch'
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
