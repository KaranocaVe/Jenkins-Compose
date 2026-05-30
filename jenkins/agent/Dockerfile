ARG INBOUND_AGENT_IMAGE=jenkins/inbound-agent:3355.v388858a_47b_33-21-jdk21
ARG DOCKER_CLI_IMAGE=docker:29.5.2-cli

FROM ${DOCKER_CLI_IMAGE} AS docker-cli

FROM ${INBOUND_AGENT_IMAGE}

USER root

COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 start-agent.sh /usr/local/bin/start-agent.sh

USER jenkins

ENTRYPOINT ["/usr/local/bin/start-agent.sh"]
