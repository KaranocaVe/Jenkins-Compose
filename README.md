# Jenkins Compose

三服务 Jenkins Compose：`controller + DinD + 常驻 agent`。

当前实现使用官方现有可用的 `Jenkins LTS + JDK 21` 镜像。原计划中的 `JDK 17` 官方 tag 已不再提供，因此这里固定到了可实际拉取和运行的 LTS 版本。

## Quick Start

1. 复制环境变量模板：

```bash
cp .env.example .env
```

2. 修改 `.env` 里的管理员密码和访问 URL。

   现在镜像版本和大部分 Jenkins 基础配置也都在 `.env` 里，可以直接按环境覆盖。

3. 启动：

```bash
docker compose up -d --build
```

4. 访问 [http://localhost:8080/login](http://localhost:8080/login) 并使用 `.env` 中的管理员账号登录。

## 结构

- `docker-compose.yml`: Jenkins、DinD、agent 三服务编排
- `jenkins/controller/`: controller 自定义镜像、插件锁定、JCasC
- `jenkins/agent/`: 常驻 inbound agent 镜像与自动注册脚本

## Config Surface

- 镜像版本已全部外提到 `.env`：`JENKINS_CONTROLLER_BUILD_IMAGE`、`JENKINS_AGENT_BUILD_IMAGE`、`DOCKER_DIND_IMAGE`、`DOCKER_CLI_IMAGE`
- Jenkins 常用配置也已外提到 `.env`：管理员名称/邮箱、controller executors、system message、agent 名称/描述/labels/executors/mode/workdir
- 运行时参数可通过 `JENKINS_OPTS` 和 `JENKINS_JAVA_OPTS_EXTRA` 继续补充
- JCasC 现在直接从镜像内 `/usr/share/jenkins/ref/casc_configs/jenkins.yaml` 读取，不再依赖 `jenkins_home` 里的拷贝文件；修改镜像或 `.env` 后，重建并重启 controller 就能生效

## 默认行为

- Jenkins 首次启动时跳过 setup wizard
- 本地管理员账号由 JCasC 自动创建
- controller `numExecutors=0`，不直接跑构建
- 常驻 agent 使用 label `docker linux`
- agent 通过 WebSocket 自动回连 Jenkins
- Docker 构建通过 TLS 访问 DinD，不挂宿主机 `docker.sock`

## 反向代理预留

- `JENKINS_URL` 用于 Jenkins 对外展示地址，可改成未来域名
- `JENKINS_INTERNAL_URL` 仅供容器内 agent 回连 controller，默认保持 `http://jenkins:8080/`
- 后续接入反向代理时，需要正确转发 `X-Forwarded-*` 请求头，并允许 WebSocket upgrade

## Smoke Test Pipeline

在 Jenkins 里创建一个 Pipeline，使用下面的最小示例验证 agent 与 DinD：

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
