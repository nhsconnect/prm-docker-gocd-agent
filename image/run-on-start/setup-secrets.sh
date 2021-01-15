#!/usr/bin/with-contenv bash

set -eo pipefail

GOCD_HOME=/home/go
AGENT_WORK_DIR="/go"

function read_aws_secret {
  local secret_id=$1
  aws ssm get-parameter --with-decryption --region $AWS_REGION --name $secret_id | jq -r ".Parameter.Value"
  if [ $? != 0 ]; then
    echo "Failed reading $secret_id from AWS SSM: ${secret_id}" >&2
    exit 1
  else
    echo "Successfully read $secret_id from AWS SSM: ${secret_id}" >&2
  fi
}

if [[ "${!GOCD_SKIP_SECRETS[@]}" ]]; then
  echo "GOCD_SKIP_SECRETS is set - will not setup go's access to most of services"
  exit 0;
fi
if [ -z "$AGENT_AUTO_REGISTER_KEY" ]; then
  echo "AGENT_AUTO_REGISTER_KEY is not set but is needed for agent to autoregister. Falling back to secret store." >&2
  # the variables exported here are not visible in services' run files
  AGENT_AUTO_REGISTER_KEY=$(read_aws_secret "/repo/${GOCD_ENVIRONMENT}/user-input/autoregister-key")
fi

echo "export AGENT_AUTO_REGISTER_KEY=${AGENT_AUTO_REGISTER_KEY}" >${GOCD_HOME}/gocd_AGENT_AUTO_REGISTER_KEY

# quotes are required to keep multiline file
mkdir -p ${GOCD_HOME}/.ssh/

chown go:go -R ${GOCD_HOME}/.ssh
