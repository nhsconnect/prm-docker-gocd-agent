# docker-gocd-agent

A docker image with Go Agent, docker daemon and Dojo.

In order to set go-agent [autoregister properties](https://docs.go.cd/current/advanced_usage/agent_auto_register.html),
 please set those environment variables, example:
```
AGENT_KEY="123456789abcdef"
AGENT_RESOURCES="private-net,docker"
AGENT_ENVIRONMENTS="env1,env2"
AGENT_HOSTNAME="go-agent-dind"
```
You can also set:
```
GO_AGENT_NAME="go-agent-15"
GO_SERVER_URL="https://127.0.0.1:8154/go"
GOCD_UID=1099
GOCD_GID=1099
```

For elastic agents:
```
ELASTIC_AGENT_ID
ELASTIC_PLUGIN_ID
```

Optional extras:
```
GO_AGENT_SYSTEM_PROPERTIES
AGENT_BOOTSTRAPPER_JVM_ARGS
```

## Secrets

There is one secret `AGENT_KEY`. It can be set as environment or it will be fetched from AWS SSM store on start.

## Volumes

You are supposed to mount
 * `/var/lib/docker` for docker in docker.
 * `/var/lib/go-agent/pipelines` for agents workspace.

## Sudo

Some agents need sudo for several commands. By default image disables sudo.
You can set `AGENT_SUDO_CONFIG` to set contents of `go` user's sudo file.
The command setting up the sudo is `echo "go ${AGENT_SUDO_CONFIG}" >> /etc/sudoers`.
So for example:
 - ultimate sudo access can be set with `ALL=(ALL) NOPASSWD: ALL`.
 - sudo for running remove: `ALL=(ALL) NOPASSWD: /bin/rm *`

## Deleting agent

To delete 1 go-agent using server API, first disable it, and then remove:
 (its guid is in: /var/lib/go-agent/config/guid.txt)
```bash
$ curl localhost:8153/go/api/agents/cb031760-29b8-46ba-bb40-436e7a077a90
 -H 'Accept: application/vnd.go.cd.v2+json'
 -H 'Content-Type: application/json' -X PATCH
 -d '{ "agent_config_state": "Disabled"}'
$ curl localhost:8153/go/api/agents/cb031760-29b8-46ba-bb40-436e7a077a90
 -H 'Accept: application/vnd.go.cd.v2+json' -X DELETE
```
