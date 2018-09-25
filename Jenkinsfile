#!groovy

/**
 * This program and the accompanying materials are made available under the terms of the
 * Eclipse Public License v2.0 which accompanies this distribution, and is available at
 * https://www.eclipse.org/legal/epl-v20.html
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Copyright IBM Corporation 2018
 */

def isPullRequest = env.BRANCH_NAME.startsWith('PR-')
def slackChannel = '#test-build-notify'

def opts = []
// keep last 20 builds for regular branches, no keep for pull requests
opts.push(buildDiscarder(logRotator(numToKeepStr: (isPullRequest ? '' : '20'))))
// disable concurrent build
opts.push(disableConcurrentBuilds())

// define custom build parameters
def customParameters = []
// >>>>>>>> parameters to control pipeline behavior
// >>>>>>>> parameters of artifactory
customParameters.push(string(
  name: 'ARTIFACTORY_URL',
  description: 'Artifactory URL',
  defaultValue: 'https://gizaartifactory.jfrog.io/gizaartifactory',
  trim: true,
  required: true
))
customParameters.push(credentials(
  name: 'ARTIFACTORY_SECRET',
  description: 'Artifactory access secret',
  credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl',
  defaultValue: 'GizaArtifactory',
  required: true
))
customParameters.push(string(
  name: 'ZOWE_BUILD_REPOSITORY',
  description: 'Zowe successful build repository',
  defaultValue: 'libs-snapshot-local',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_BUILD_NAME',
  description: 'Zowe successful build name',
  defaultValue: 'zowe-install-packaging :: master',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_BUILD_NUMBER',
  description: 'REQUIRED. Zowe successful build number',
  defaultValue: '',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_RELEASE_REPOSITORY',
  description: 'Zowe release repository',
  defaultValue: 'libs-release-local',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_RELEASE_PATH',
  description: 'Zowe release path',
  defaultValue: '/org/zowe',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_RELEASE_CATEGORY',
  description: 'REQUIRED. Zowe release category. For example, stable',
  defaultValue: 'stable',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_RELEASE_VERSION',
  description: 'REQUIRED. Zowe release version without prefix v. For example, 0.9.0',
  defaultValue: '',
  trim: true,
  required: true
))
// >>>>>>>> SSH access of testing server zOSaaS layer
customParameters.push(string(
  name: 'PUBLISH_SSH_HOST',
  description: 'Host of publishing server',
  defaultValue: 'wash.zowe.org',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'PUBLISH_SSH_PORT',
  description: 'SSH port of publishing server',
  defaultValue: '22',
  trim: true,
  required: true
))
customParameters.push(credentials(
  name: 'PUBLISH_SSH_CREDENTIAL',
  description: 'The SSH credential used to connect publishing server',
  credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl',
  defaultValue: 'ssh-zowe-publish',
  required: true
))
customParameters.push(string(
  name: 'PUBLISH_DIRECTORY',
  description: 'Publishing directory',
  defaultValue: '/var/www/projectgiza.org/builds',
  trim: true,
  required: true
))

opts.push(parameters(customParameters))

// set build properties
properties(opts)

node ('ibm-jenkins-slave-nvm') {
  currentBuild.result = 'SUCCESS'

  def releaseFilename = "zowe-${params.ZOWE_RELEASE_VERSION}.pax"
  def releaseFileFull = "${params.ZOWE_RELEASE_REPOSITORY}${params.ZOWE_RELEASE_PATH}/${params.ZOWE_RELEASE_VERSION}/${releaseFilename}"

  try {

    stage('checkout') {
      // checkout source code
      checkout scm

      // check if it's pull request
      echo "Current branch is ${env.BRANCH_NAME}"
      if (isPullRequest) {
        echo "This is a pull request"
      }
    }

    stage('promote') {
      if (!params.ZOWE_RELEASE_REPOSITORY) {
        error "ZOWE_RELEASE_REPOSITORY is required to promote build."
      }
      if (!params.ZOWE_BUILD_NAME) {
        error "ZOWE_BUILD_NAME is required to promote build."
      }
      if (!params.ZOWE_BUILD_NUMBER) {
        error "ZOWE_BUILD_NUMBER is required to promote build."
      }
      if (!params.ZOWE_RELEASE_CATEGORY) {
        error "ZOWE_RELEASE_CATEGORY is required to promote build."
      }
      if (!params.ZOWE_RELEASE_VERSION) {
        error "ZOWE_RELEASE_VERSION is required to promote build."
      }

      // prepare JFrog CLI configurations
      withCredentials([usernamePassword(credentialsId: params.ARTIFACTORY_SECRET, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        sh "jfrog rt config rt-server-1 --url=${params.ARTIFACTORY_URL} --user=${USERNAME} --password=${PASSWORD}"
      }

      // get build information
      def buildsInfoText = sh(
        script: "jfrog rt search --build=\"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\" ${params.ZOWE_BUILD_REPOSITORY}/*.pax",
        returnStdout: true
      ).trim()
      /**
       * Example result:
       *
       * [
       *   {
       *     "path": "libs-snapshot-local/com/project/zowe/0.9.0-SNAPSHOT/zowe-0.9.0-20180918.163158-38.pax",
       *     "props": {
       *       "build.name": "zowe-install-packaging :: master",
       *       "build.number": "38",
       *       "build.parentName": "zlux",
       *       "build.parentNumber": "570",
       *       "build.timestamp": "1537287202277"
       *     }
       *   }
       * ]
       */
      def buildsInfo = readJSON text: buildsInfoText
      def buildSize = buildsInfo.size()
      if (buildSize < 1) {
        error "Cannot find build \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\""
      }
      if (buildSize > 1) {
        error "Found ${buildSize} builds for \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\""
      }
      def buildInfo = buildsInfo.first()
      if (!buildInfo || !buildInfo.path) {
        error "Failed to find build artifactory."
      }

      // extract build information
      def buildTimestamp = buildInfo.props.get('build.timestamp')
      // think this should be a bug
      // readJSON returns buildTimestamp as net.sf.json.JSONArray
      // this step is a workaround
      if (buildTimestamp.getClass().toString().endsWith('JSONArray')) {
        buildTimestamp = buildTimestamp.get(0)
      }
      echo "Build \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\":"
      echo "- pax path       : ${buildInfo.path}"
      echo "- build timestamp: ${buildTimestamp}"

      // copy artifact
      echo "===================== Promoting (copying) ===================== "
      echo "- from: ${buildInfo.path}"
      echo "-   to: ${releaseFileFull}"
      sh "jfrog rt copy --flat \"${buildInfo.path}\" \"${releaseFileFull}\""

      // update file property
      def props = []
      def currentBuildName = env.JOB_NAME.replace('/', ' :: ')
      props << "build.name=${currentBuildName}"
      props << "build.number=${env.BUILD_NUMBER}"
      props << "build.parentName=${params.ZOWE_BUILD_NAME}"
      props << "build.parentNumber=${params.ZOWE_BUILD_NUMBER}"
      props << "build.timestamp=${buildTimestamp}"
      echo "===================== File properties ===================== "
      echo props.join("\n")
      sh "jfrog rt set-props \"${releaseFileFull}\" \"" + props.join(';') + "\""
    }

    stage('publish') {
      // download build
      sh "jfrog rt download --flat \"${releaseFileFull}\""

      withCredentials([usernamePassword(credentialsId: params.PUBLISH_SSH_CREDENTIAL, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        // upload to publish server
        sh """SSHPASS=${PASSWORD} sshpass -e sftp -o BatchMode=no -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -b - -P ${params.PUBLISH_SSH_PORT} ${USERNAME}@${params.PUBLISH_SSH_HOST} << EOF
put ${releaseFilename}
put scripts/zowe-publish.sh
bye
EOF"""

        // move to target folder, split and generate hash
        sh """SSHPASS=${PASSWORD} sshpass -e ssh -tt -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -p ${params.PUBLISH_SSH_PORT} ${USERNAME}@${params.PUBLISH_SSH_HOST} << EOF
cd ~ && chmod +x zowe-publish.sh && ./zowe-publish.sh "${params.PUBLISH_DIRECTORY}" "${params.ZOWE_RELEASE_CATEGORY}" "${params.ZOWE_RELEASE_VERSION}" || exit 1
exit 0
EOF"""
      }

    }

    stage('done') {
      emailext body: "Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} succeeded.\n\nCheck detail: ${env.BUILD_URL}" ,
          subject: "[Jenkins] Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} succeeded",
          recipientProviders: [
            [$class: 'RequesterRecipientProvider'],
            [$class: 'CulpritsRecipientProvider'],
            [$class: 'DevelopersRecipientProvider'],
            [$class: 'UpstreamComitterRecipientProvider']
          ]
    }

  } catch (err) {
    currentBuild.result = 'FAILURE'

    emailext body: "Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} failed.\n\nError: ${err}\n\nCheck detail: ${env.BUILD_URL}" ,
        subject: "[Jenkins] Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} failed",
        recipientProviders: [
          [$class: 'RequesterRecipientProvider'],
          [$class: 'CulpritsRecipientProvider'],
          [$class: 'DevelopersRecipientProvider'],
          [$class: 'UpstreamComitterRecipientProvider']
        ]

    throw err
  }
}
