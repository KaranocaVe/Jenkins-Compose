#!/bin/sh
set -eu

jenkins_url="${JENKINS_INTERNAL_URL:-http://jenkins:8080/}"
jenkins_url="${jenkins_url%/}"
agent_name="${JENKINS_AGENT_NAME:-docker-agent-1}"
agent_workdir="${JENKINS_AGENT_WORKDIR:-/home/jenkins/agent}"
docker_cert_path="${DOCKER_CERT_PATH:-/certs/client}"
auth_user="${JENKINS_ADMIN_ID:?JENKINS_ADMIN_ID is required}"
auth_pass="${JENKINS_ADMIN_PASSWORD:?JENKINS_ADMIN_PASSWORD is required}"
jnlp_url="${jenkins_url}/computer/${agent_name}/slave-agent.jnlp"

mkdir -p "${agent_workdir}"

if [ -n "${DOCKER_HOST:-}" ]; then
  echo "Waiting for Docker daemon at ${DOCKER_HOST}..."
  until [ -r "${docker_cert_path}/ca.pem" ] && docker version >/dev/null 2>&1; do
    sleep 3
  done
fi

echo "Waiting for Jenkins at ${jenkins_url}..."
until curl -fsS "${jenkins_url}/login" >/dev/null; do
  sleep 5
done

echo "Waiting for agent definition ${agent_name}..."
agent_secret=""
until [ -n "${agent_secret}" ]; do
  jnlp_xml="$(curl -fsS -u "${auth_user}:${auth_pass}" "${jnlp_url}" 2>/dev/null || true)"
  agent_secret="$(printf '%s\n' "${jnlp_xml}" | grep -o '<argument>[^<]*</argument>' | sed -n '1s#<argument>\(.*\)</argument>#\1#p')"
  if [ -z "${agent_secret}" ]; then
    sleep 5
  fi
done

unset JENKINS_AGENT_NAME
unset JENKINS_AGENT_WORKDIR

exec jenkins-agent \
  -name "${agent_name}" \
  -secret "${agent_secret}" \
  -url "${jenkins_url}/" \
  -webSocket \
  -workDir "${agent_workdir}"
