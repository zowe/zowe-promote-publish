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
def zoweInstallPackagingRepo = 'zowe/zowe-install-packaging'

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
  description: 'REQUIRED if ZOWE_BUILD_RC_PATH is empty. Zowe successful build number',
  defaultValue: '',
  trim: true
))
customParameters.push(string(
  name: 'ZOWE_BUILD_RC_PATH',
  description: 'REQUIRED if ZOWE_BUILD_NUMBER is empty. Zowe RC build artifactory download path. If the build original file has been removed from artifactory, we can promote any existing file. Example: libs-release-local/org/zowe/0.9.3-RC2/zowe-0.9.3-RC2.pax',
  defaultValue: '',
  trim: true
))
customParameters.push(string(
  name: 'ZOWE_CLI_BUILD_REPOSITORY',
  description: 'Zowe CLI successful build repository',
  defaultValue: 'libs-snapshot-local',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_CLI_BUILD_NAME',
  description: 'Zowe CLI successful build name',
  defaultValue: 'Zowe CLI Bundle :: master',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'ZOWE_CLI_BUILD_NUMBER',
  description: 'REQUIRED if ZOWE_CLI_BUILD_RC_PATH is empty. Zowe CLI successful build number',
  defaultValue: '',
  trim: true
))
customParameters.push(string(
  name: 'ZOWE_CLI_BUILD_RC_PATH',
  description: 'REQUIRED if ZOWE_CLI_BUILD_NUMBER is empty. Zowe CLI build artifactory download path. If the build original file has been removed from artifactory, we can promote any existing file. Example: libs-release-local/org/zowe/0.9.3-RC2/zowe-cli-package-0.9.3.zip',
  defaultValue: '',
  trim: true
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
customParameters.push(credentials(
  name: 'GITHUB_CREDENTIALS',
  description: 'Github user credentials',
  credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl',
  defaultValue: 'zowe-robot-github',
  required: true
))
customParameters.push(string(
  name: 'GITHUB_USER_EMAIL',
  description: 'github user email',
  defaultValue: 'zowe.robot@gmail.com',
  trim: true,
  required: true
))
customParameters.push(string(
  name: 'GITHUB_USER_NAME',
  description: 'github user name',
  defaultValue: 'Zowe Robot',
  trim: true,
  required: true
))

opts.push(parameters(customParameters))

// set build properties
properties(opts)

node ('ibm-jenkins-slave-nvm') {
  currentBuild.result = 'SUCCESS'

  def releaseFilename = "zowe-${params.ZOWE_RELEASE_VERSION}.pax"
  def releaseCliFilename = "zowe-cli-package-${params.ZOWE_RELEASE_VERSION}.zip"
  def releaseFilePath = "${params.ZOWE_RELEASE_REPOSITORY}${params.ZOWE_RELEASE_PATH}/${params.ZOWE_RELEASE_VERSION}"
  def releaseFileFull = "${releaseFilePath}/${releaseFilename}"
  def releaseCliFileFull = "${releaseFilePath}/${releaseCliFilename}"
  def isFormalRelease = false
  def gitRevision = null
  def gitCliRevision = null

  try {

    stage('validate') {
      if (!params.ZOWE_RELEASE_REPOSITORY) {
        error "ZOWE_RELEASE_REPOSITORY is required to promote build."
      }
      if (!params.ZOWE_BUILD_NAME) {
        error "ZOWE_BUILD_NAME is required to promote build."
      }
      if (!params.ZOWE_BUILD_NUMBER && !params.ZOWE_BUILD_RC_PATH) {
        error "ZOWE_BUILD_NUMBER or ZOWE_BUILD_RC_PATH is required to promote build."
      }
      if (!params.ZOWE_CLI_BUILD_NAME) {
        error "ZOWE_CLI_BUILD_NAME is required to promote build."
      }
      if (!params.ZOWE_CLI_BUILD_NUMBER && !params.ZOWE_CLI_BUILD_RC_PATH) {
        error "ZOWE_CLI_BUILD_NUMBER or ZOWE_CLI_BUILD_RC_PATH is required to promote build."
      }
      if (!params.ZOWE_RELEASE_CATEGORY) {
        error "ZOWE_RELEASE_CATEGORY is required to promote build."
      }
      if (!params.ZOWE_RELEASE_VERSION) {
        error "ZOWE_RELEASE_VERSION is required to promote build."
      }

      // thanks semver/semver, this regular expression comes from
      // https://github.com/semver/semver/issues/232#issuecomment-405596809
      if (!(params.ZOWE_RELEASE_VERSION ==~ /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/)) {
        error "${params.ZOWE_RELEASE_VERSION} is not a valid semantic version."
      }
      if (params.ZOWE_RELEASE_VERSION ==~ /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/) {
        isFormalRelease = true
        echo ">>>> Version ${params.ZOWE_RELEASE_VERSION} is considered as a FORMAL RELEASE."
      } else {
        echo ">>>> Version ${params.ZOWE_RELEASE_VERSION} is NOT considered as a FORMAL RELEASE."
      }

      echo "Checking if ${params.ZOWE_RELEASE_VERSION} already exists ..."

      // prepare JFrog CLI configurations
      withCredentials([usernamePassword(credentialsId: params.ARTIFACTORY_SECRET, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        sh "jfrog rt config rt-server-1 --url=${params.ARTIFACTORY_URL} --user=${USERNAME} --password=${PASSWORD}"
      }

      // check artifactory
      def versionOnArtifactory = sh(
        script: "jfrog rt s \"${releaseFilePath}/\"",
        returnStdout: true
      ).trim()
      echo "Search result: ${versionOnArtifactory}"
      if (versionOnArtifactory != '[]') {
        error "Zowe version ${params.ZOWE_RELEASE_VERSION} already exists (${releaseFilePath})"
      } else {
        echo ">>>> Target artifactory folder doesn't exist, may proceed."
      }

      // check build info
      withCredentials([usernamePassword(credentialsId: params.ARTIFACTORY_SECRET, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        if (params.ZOWE_BUILD_NUMBER) {
          // FIXME: this could be risky if build name including non-ASCII characters
          def encodedBuildName = params.ZOWE_BUILD_NAME.replace(' ', '%20')
          gitRevision = sh(
            script: "curl -u \"${USERNAME}:${PASSWORD}\" -sS \"${params.ARTIFACTORY_URL}/api/build/${encodedBuildName}/${params.ZOWE_BUILD_NUMBER}\" | jq \".buildInfo.vcsRevision\"",
            returnStdout: true
          ).trim()
          gitRevision = gitRevision.replace('"', '')
          if (!(gitRevision ==~ /^[0-9a-fA-F]{40}$/)) { // if it's a SHA-1 commit hash
            error "Cannot extract git revision from build \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\""
          }
          echo ">>>> Build ${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER} commit hash is ${gitRevision}, may proceed."
        }
        if (params.ZOWE_CLI_BUILD_NUMBER) {
          def encodedCliBuildName = params.ZOWE_CLI_BUILD_NAME.replace(' ', '%20')
          gitCliRevision = sh(
            script: "curl -u \"${USERNAME}:${PASSWORD}\" -sS \"${params.ARTIFACTORY_URL}/api/build/${encodedCliBuildName}/${params.ZOWE_CLI_BUILD_NUMBER}\" | jq \".buildInfo.vcsRevision\"",
            returnStdout: true
          ).trim()
          gitCliRevision = gitCliRevision.replace('"', '')
          if (!(gitCliRevision ==~ /^[0-9a-fA-F]{40}$/)) { // if it's a SHA-1 commit hash
            error "Cannot extract git revision from build \"${params.ZOWE_CLI_BUILD_NAME}/${params.ZOWE_CLI_BUILD_NUMBER}\""
          }
          echo ">>>> Build ${params.ZOWE_CLI_BUILD_NAME}/${params.ZOWE_CLI_BUILD_NUMBER} commit hash is ${gitCliRevision}, may proceed."
        }
      }

      // check deploy target directory
      withCredentials([usernamePassword(credentialsId: params.PUBLISH_SSH_CREDENTIAL, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        // move to target folder, split and generate hash
        def versionOnPublishDir = sh(script:"""SSHPASS=${PASSWORD} sshpass -e ssh -tt -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -p ${params.PUBLISH_SSH_PORT} ${USERNAME}@${params.PUBLISH_SSH_HOST} << EOF
[ -d '${params.PUBLISH_DIRECTORY}/${params.ZOWE_RELEASE_CATEGORY}/${params.ZOWE_RELEASE_VERSION}' ] && exit 1
exit 0
EOF""", returnStatus:true)
        echo "Exit code: ${versionOnPublishDir}"
        if ("${versionOnPublishDir}" == "1") {
          error "Zowe version ${params.ZOWE_RELEASE_VERSION} already exists (${params.PUBLISH_DIRECTORY}/${params.ZOWE_RELEASE_CATEGORY}/${params.ZOWE_RELEASE_VERSION})"
        } else {
          echo ">>>> Target publish folder doesn't exist, may proceed."
        }
      }
    }

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
      // get build information
      def artifactorySearch = ""
      if (params.ZOWE_BUILD_NUMBER) {
        artifactorySearch = "--build=\"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\" ${params.ZOWE_BUILD_REPOSITORY}/*"
      } else if (params.ZOWE_BUILD_RC_PATH) {
        artifactorySearch = "\"${params.ZOWE_BUILD_RC_PATH}\""
      } else {
        error "No file to promote"
      }
      def buildsInfoText = sh(
        script: "jfrog rt search ${artifactorySearch}",
        returnStdout: true
      ).trim()
      echo "Build/file search result:"
      echo buildsInfoText
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
        if (params.ZOWE_BUILD_NUMBER) {
          error "Cannot find build \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\""
        } else if (params.ZOWE_BUILD_RC_PATH) {
          error "Cannot find file \"${params.ZOWE_BUILD_RC_PATH}\""
        }
      }
      if (buildSize > 1) {
        if (params.ZOWE_BUILD_NUMBER) {
          error "Found ${buildSize} builds for \"${params.ZOWE_BUILD_NAME}/${params.ZOWE_BUILD_NUMBER}\""
        } else if (params.ZOWE_BUILD_RC_PATH) {
          error "Found ${buildSize} files for \"${params.ZOWE_BUILD_RC_PATH}\""
        }
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
      // get original build name/number
      def buildName = buildInfo.props.get('build.name')
      if (buildName.getClass().toString().endsWith('JSONArray')) {
        buildName = buildName.get(0)
      }
      def buildNumber = buildInfo.props.get('build.number')
      if (buildNumber.getClass().toString().endsWith('JSONArray')) {
        buildNumber = buildNumber.get(0)
      }
      if (buildName.contains('zowe-promote-publish')) {
        // find parent build
        buildName = buildInfo.props.get('build.parentName')
        if (buildName.getClass().toString().endsWith('JSONArray')) {
          buildName = buildName.get(0)
        }
        buildNumber = buildInfo.props.get('build.parentNumber')
        if (buildNumber.getClass().toString().endsWith('JSONArray')) {
          buildNumber = buildNumber.get(0)
        }
      }
      echo "Build \"${buildName}/${buildNumber}\":"
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
      props << "build.parentName=${buildName}"
      props << "build.parentNumber=${buildNumber}"
      props << "build.timestamp=${buildTimestamp}"
      echo "===================== File properties ===================== "
      echo props.join("\n")
      sh "jfrog rt set-props \"${releaseFileFull}\" \"" + props.join(';') + "\""

      // FIXME: move the similar process to library
      // >>>> promote CLI package
      // get build information
      def cliArtifactorySearch = ""
      if (params.ZOWE_CLI_BUILD_NUMBER) {
        cliArtifactorySearch = "--build=\"${params.ZOWE_CLI_BUILD_NAME}/${params.ZOWE_CLI_BUILD_NUMBER}\" ${params.ZOWE_CLI_BUILD_REPOSITORY}/*"
      } else if (params.ZOWE_CLI_BUILD_RC_PATH) {
        cliArtifactorySearch = "\"${params.ZOWE_CLI_BUILD_RC_PATH}\""
      } else {
        error "No file to promote"
      }
      def cliBuildsInfoText = sh(
        script: "jfrog rt search ${cliArtifactorySearch}",
        returnStdout: true
      ).trim()
      echo "Build/file search result:"
      echo cliBuildsInfoText
      /**
       * Example result:
       *
       * [
       *   {
       *     "path": "libs-snapshot-local/org/zowe/cli/zowe-cli-package/0.9.5-SNAPSHOT/zowe-cli-package-0.9.5-20181126.171303-1.zip",
       *     "props": {
       *       "build.name": "Zowe CLI Bundle :: master",
       *       "build.number": "23",
       *       "build.timestamp": "1543252383120",
       *       "vcs.revision": "be679f4fd22eab20dbd17ab32d88a6c76d0ae70b"
       *     }
       *   }
       * ]
       */
      def cliBuildsInfo = readJSON text: cliBuildsInfoText
      def cliBuildSize = cliBuildsInfo.size()
      if (cliBuildSize < 1) {
        if (params.ZOWE_CLI_BUILD_NUMBER) {
          error "Cannot find build \"${params.ZOWE_CLI_BUILD_NAME}/${params.ZOWE_CLI_BUILD_NUMBER}\""
        } else if (params.ZOWE_CLI_BUILD_RC_PATH) {
          error "Cannot find file \"${params.ZOWE_CLI_BUILD_RC_PATH}\""
        }
      }
      if (cliBuildSize > 1) {
        if (params.ZOWE_CLI_BUILD_NUMBER) {
          error "Found ${cliBuildSize} builds for \"${params.ZOWE_CLI_BUILD_NAME}/${params.ZOWE_CLI_BUILD_NUMBER}\""
        } else if (params.ZOWE_CLI_BUILD_RC_PATH) {
          error "Found ${cliBuildSize} files for \"${params.ZOWE_CLI_BUILD_RC_PATH}\""
        }
      }
      def cliBuildInfo = cliBuildsInfo.first()
      if (!cliBuildInfo || !cliBuildInfo.path) {
        error "Failed to find build artifactory."
      }

      // extract build information
      def cliBuildTimestamp = cliBuildInfo.props.get('build.timestamp')
      // think this should be a bug
      // readJSON returns cliBuildTimestamp as net.sf.json.JSONArray
      // this step is a workaround
      if (cliBuildTimestamp.getClass().toString().endsWith('JSONArray')) {
        cliBuildTimestamp = cliBuildTimestamp.get(0)
      }
      // get original build name/number
      def cliBuildName = cliBuildInfo.props.get('build.name')
      if (cliBuildName.getClass().toString().endsWith('JSONArray')) {
        cliBuildName = cliBuildName.get(0)
      }
      def cliBuildNumber = cliBuildInfo.props.get('build.number')
      if (cliBuildNumber.getClass().toString().endsWith('JSONArray')) {
        cliBuildNumber = cliBuildNumber.get(0)
      }
      if (cliBuildName.contains('zowe-promote-publish')) {
        // find parent build
        cliBuildName = cliBuildInfo.props.get('build.parentName')
        if (cliBuildName.getClass().toString().endsWith('JSONArray')) {
          cliBuildName = cliBuildName.get(0)
        }
        cliBuildNumber = cliBuildInfo.props.get('build.parentNumber')
        if (cliBuildNumber.getClass().toString().endsWith('JSONArray')) {
          cliBuildNumber = cliBuildNumber.get(0)
        }
      }
      echo "CLI Build \"${cliBuildName}/${cliBuildNumber}\":"
      echo "- zip path       : ${cliBuildInfo.path}"
      echo "- build timestamp: ${cliBuildTimestamp}"

      // copy artifact
      echo "===================== Promoting (copying) ===================== "
      echo "- from: ${cliBuildInfo.path}"
      echo "-   to: ${releaseCliFileFull}"
      sh "jfrog rt copy --flat \"${cliBuildInfo.path}\" \"${releaseCliFileFull}\""

      // update file property
      def cliProps = []
      def currentcliBuildName = env.JOB_NAME.replace('/', ' :: ')
      cliProps << "build.name=${currentcliBuildName}"
      cliProps << "build.number=${env.BUILD_NUMBER}"
      cliProps << "build.parentName=${cliBuildName}"
      cliProps << "build.parentNumber=${cliBuildNumber}"
      cliProps << "build.timestamp=${cliBuildTimestamp}"
      echo "===================== File properties ===================== "
      echo cliProps.join("\n")
      sh "jfrog rt set-props \"${releaseCliFileFull}\" \"" + cliProps.join(';') + "\""
    }

    utils.conditionalStage('tag', isFormalRelease) {
      // tag the repositories for a formal release
      sh """
        git config --global user.email \"${params.GITHUB_USER_EMAIL}\"
        git config --global user.name \"${params.GITHUB_USER_NAME}\"
      """
      withCredentials([usernamePassword(
        credentialsId: params.GITHUB_CREDENTIALS,
        passwordVariable: 'GIT_PASSWORD',
        usernameVariable: 'GIT_USERNAME'
      )]) {
        // tag zowe-install-packaging repository
        sh """
        mkdir .zowe-install-packaging
        cd .zowe-install-packaging
        git init
        git remote add origin https://github.com/${zoweInstallPackagingRepo}.git
        git fetch origin
        git checkout ${gitRevision}
        git tag v${params.ZOWE_RELEASE_VERSION}
        git push --tags 'https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${zoweInstallPackagingRepo}.git'
        """
      }
    }

    stage('publish') {
      // download build
      sh "jfrog rt download --flat \"${releaseFileFull}\""
      sh "jfrog rt download --flat \"${releaseCliFileFull}\""

      withCredentials([usernamePassword(credentialsId: params.PUBLISH_SSH_CREDENTIAL, passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
        // upload to publish server
        sh """SSHPASS=${PASSWORD} sshpass -e sftp -o BatchMode=no -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -b - -P ${params.PUBLISH_SSH_PORT} ${USERNAME}@${params.PUBLISH_SSH_HOST} << EOF
put ${releaseFilename}
put ${releaseCliFilename}
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
      def source = ""
      if (params.ZOWE_BUILD_NUMBER) {
        source = "Build #${params.ZOWE_BUILD_NUMBER}"
      } else if (params.ZOWE_BUILD_RC_PATH) {
        source = "File \"${params.ZOWE_BUILD_RC_PATH}\""
      }
      def successMsg = """
*************************************************************************************************

${source} is promoted as Zowe v${params.ZOWE_RELEASE_VERSION}, you can download from:

${params.ARTIFACTORY_URL}/${releaseFileFull}
or:
https://projectgiza.org/builds/${params.ZOWE_RELEASE_CATEGORY}/${params.ZOWE_RELEASE_VERSION}/${releaseFilename}

The CLI Standalone Package is published here:
${params.ARTIFACTORY_URL}/${releaseCliFileFull}
or:
https://projectgiza.org/builds/${params.ZOWE_RELEASE_CATEGORY}/${params.ZOWE_RELEASE_VERSION}/${releaseCliFilename}

*************************************************************************************************
      """
      echo successMsg

      emailext body: "Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} succeeded.\n\nCheck detail: ${env.BUILD_URL}" ,
          subject: "[Jenkins] Job \"${env.JOB_NAME}\" build #${env.BUILD_NUMBER} succeeded\n\n${successMsg}",
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
