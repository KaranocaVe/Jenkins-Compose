ARG JENKINS_IMAGE=jenkins/jenkins:2.555.2-lts-jdk21
FROM ${JENKINS_IMAGE}

ARG JENKINS_UC=https://mirrors.huaweicloud.com/jenkins/update-center.json
ARG JENKINS_UC_EXPERIMENTAL=https://mirrors.huaweicloud.com/jenkins/experimental/update-center.json
ARG JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

ENV JENKINS_UC=${JENKINS_UC} \
    JENKINS_UC_EXPERIMENTAL=${JENKINS_UC_EXPERIMENTAL} \
    JENKINS_INCREMENTALS_REPO_MIRROR=${JENKINS_INCREMENTALS_REPO_MIRROR}

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY --chown=jenkins:jenkins casc/ /usr/share/jenkins/ref/casc_configs/
