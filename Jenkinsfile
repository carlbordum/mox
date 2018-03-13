// -*- groovy -*-

pipeline {
  agent any

  stages {
    stage('Test') {
      steps {
        echo 'Testing oio_rest...'

        timeout(15) {
          ansiColor('xterm') {
            sh 'oio_rest/run_tests.sh'
          }
        }
      }
    }
  }

  post {
    always {
      junit healthScaleFactor: 200.0,           \
        testResults: 'oio_rest/tests.xml'

      cobertura coberturaReportFile: 'oio_rest/coverage.xml',    \
        maxNumberOfBuilds: 0
    }
  }
}