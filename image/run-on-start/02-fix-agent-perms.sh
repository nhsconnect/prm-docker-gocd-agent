#!/bin/bash

echo "Starting go-agent permissions fix"
set -x
mkdir -p "/var/lib/go-agent/pipelines"
chown go:go -R "/var/lib/go-agent"
chown go:go -R "/var/go"
chown go:go "/etc/default/go-agent"
set +x
echo "Done go-agent permissions fix."
