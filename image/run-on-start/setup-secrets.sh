#!/usr/bin/with-contenv bash

set -e

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


if [ -z "$GOCD_ENVIRONMENT" ]; then
  echo "GOCD_ENVIRONMENT is not set. It is needed for go agent to get autoregister key"
  exit 3
fi

if [ -z "$AGENT_KEY" ]; then
  echo "AGENT_KEY is not set. It is needed for go agent to autoregister"
  # the variables exported here are not visible in services' run files
  AGENT_KEY=$(read_aws_secret "/NHS/deductions-327778747031/gocd-${GOCD_ENVIRONMENT}/autoregister_key")
fi

echo "export AGENT_KEY=${AGENT_KEY}" >> /var/go/gocd_agent_key

mkdir -p /var/go/
chown go:go -R /var/go/.ssh
