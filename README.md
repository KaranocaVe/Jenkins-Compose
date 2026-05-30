# Jenkins Compose

A three-service Jenkins Compose stack: `controller + DinD + persistent agent`.

This implementation uses the currently available official `Jenkins LTS + JDK 21` images. The original `JDK 17` plan is not used because the official `jdk17` tags are no longer published on Docker Hub.

## Quick Start

1. Copy the environment template:

```bash
cp .env.example .env
```

2. Update the admin password and access URL in `.env`.

   Image versions and most Jenkins baseline settings are also exposed through `.env`, so they can be overridden per environment.

3. Start the stack:

```bash
docker compose up -d --build
```

4. Open [http://localhost:8080/login](http://localhost:8080/login) and sign in with the admin credentials from `.env`.

## Structure

- `docker-compose.yml`: orchestration for Jenkins, DinD, and the persistent agent
- `jenkins/controller/`: custom controller image, pinned plugins, and JCasC
- `jenkins/agent/`: persistent inbound agent image and auto-registration script

## Config Surface

- All image versions are exposed through `.env`: `JENKINS_CONTROLLER_BUILD_IMAGE`, `JENKINS_AGENT_BUILD_IMAGE`, `DOCKER_DIND_IMAGE`, and `DOCKER_CLI_IMAGE`
- The Jenkins update center mirror is exposed through `.env`: `JENKINS_UC`, `JENKINS_PLUGIN_INFO`, `JENKINS_UC_DOWNLOAD`, `JENKINS_UC_DOWNLOAD_URL`, `JENKINS_UC_EXPERIMENTAL`, and `JENKINS_INCREMENTALS_REPO_MIRROR`
- Common Jenkins settings are also exposed through `.env`: admin name/email, controller executors, system message, and agent name/description/labels/executors/mode/workdir
- Extra runtime options can be appended through `JENKINS_OPTS` and `JENKINS_JAVA_OPTS_EXTRA`
- JCasC now loads directly from `/usr/share/jenkins/ref/casc_configs/jenkins.yaml` inside the image instead of relying on a copied file in `jenkins_home`; after changing the image or `.env`, rebuild and restart the controller to apply the update

## Update Center Mirror

- The default configuration now points Jenkins and `jenkins-plugin-cli` to the Huawei Cloud mirror
- The configured default is `https://mirrors.huaweicloud.com/jenkins/update-center.json`
- Plugin binaries are downloaded from `https://mirrors.huaweicloud.com/jenkins/plugins`
- The previously suggested `https://mirrors.huaweicloud.com/jenkins/updates/update-center.json` currently returns `404`, so it is not used as the default

## Default Behavior

- Jenkins skips the setup wizard on first boot
- The local admin account is created automatically by JCasC
- The controller runs with `numExecutors=0` and does not execute builds directly
- The persistent agent uses the `docker linux` label set
- The agent reconnects to Jenkins automatically over WebSocket
- Docker builds use TLS to talk to DinD and do not mount the host `docker.sock`

## Reverse Proxy Readiness

- `JENKINS_URL` is the external Jenkins URL and can be changed to a future domain
- `JENKINS_INTERNAL_URL` is only used by the containerized agent to reconnect to the controller and should usually stay `http://jenkins:8080/`
- When adding a reverse proxy later, it must forward `X-Forwarded-*` headers correctly and allow WebSocket upgrade requests

## Smoke Test Pipeline

Create a Jenkins Pipeline and use the following minimal example to verify the agent-to-DinD path:

```groovy
pipeline {
  agent { label 'docker' }

  stages {
    stage('Verify Tooling') {
      steps {
        sh '''
          set -eux
          git --version
          docker version
          printf '%s\n' 'FROM alpine:3.22' 'CMD ["sh", "-c", "echo smoke-test"]' > Dockerfile
          docker build -t jenkins-compose-smoke .
          docker run --rm jenkins-compose-smoke
        '''
      }
    }
  }
}
```
