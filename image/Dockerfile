FROM ubuntu:18.04

# Nano, curl is for humans administrating/experimenting.
# Cron is for renewing vault tokens.
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends\
  git tzdata wget curl ca-certificates nano cron tar zip unzip bzip2 sudo rsync apt-transport-https ssh-client &&\
  apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean &&\
  rm -rf /tmp/* /var/tmp/* && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 0.4.0 https://github.com/kudulab/ops-base.git /tmp/ops-base &&\
   cd /tmp/ops-base/setup &&\
   SKIP_VAULT=true ./install.sh &&\
   cd / && rm -rf /python-ops

RUN pip3 install awscli --upgrade

# Install s6 without ADD, so that it is cached in a docker layer.
# Workaround for debian slim docker image from:
# https://github.com/just-containers/s6-overlay/issues/125#issuecomment-321615127
RUN wget -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.1/s6-overlay-amd64.tar.gz &&\
  tar xvfz /tmp/s6-overlay.tar.gz -C / &&\
  rm -f /tmp/s6-overlay.tar.gz
ENTRYPOINT ["/init"]

# Install Docker
# To support docker in docker on any driver - clean up now and
# declare volume to bypass any storage drivers
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&\
  add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" &&\
  apt-get update &&\
  apt-get install -y docker-ce docker-ce-cli containerd.io &&\
  rm -Rf /var/lib/docker/* &&\
  rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* /var/tmp/*
VOLUME /var/lib/docker

ENV DOCKER_BASE_OPTS="--data-root=/var/lib/docker -H unix:///var/run/docker.sock"
ENV DOCKER_OPTS="--storage-driver overlay2"

# Install go-agent
## Configure go linux user and its identity
ENV AWS_REGION="eu-west-2" \
  AGENT_KEY="" \
  AGENT_RESOURCES="docker" \
  AGENT_HOSTNAME="go-agent-dind" \
  TERM="xterm"
# First setup go linux user, then install Go Agent packages, because they create
# go linux user identity too.
COPY go-identity /var/go/
COPY ssh_config /etc/ssh/ssh_config
COPY sshd_config /etc/ssh/sshd_config
# Go uid should be 1000 for efficiency.
RUN groupadd go --gid 1000 &&\
  useradd go --uid 1000 --gid 1000 --home /var/go --shell /bin/bash --password "$1$JJsvHslasdfjVEroftprNn4JHtDi" &&\
  mkdir -p /var/go && chmod 0755 /var/go &&\
  mkdir -p /var/go/.ssh && chmod 0700 /var/go/.ssh &&\
  chmod 0755 /var/go/.bashrc /var/go/.bashrc.d /var/go/.profile &&\
  chmod 0600 /var/go/.bashrc.d/* &&\
  chown go:go -R /var/go &&\
  usermod -aG docker go

RUN DEBIAN_FRONTEND=noninteractive apt-get update &&\
  apt-get install -y --no-install-recommends \
  openjdk-8-jre &&\
  rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* /var/tmp/*

RUN wget -O /tmp/go-agent.deb https://download.gocd.org/binaries/19.3.0-8959/deb/go-agent_19.3.0-8959_all.deb &&\
  dpkg -i /tmp/go-agent.deb &&\
  rm /tmp/go-agent.deb

# Add all the services
COPY ./services.d /etc/services.d
COPY run-on-start/* /etc/cont-init.d/
# ensure that logs are printed to console output
COPY agent-bootstrapper-logback-include.xml /var/lib/go-agent/config/agent-bootstrapper-logback-include.xml
COPY agent-launcher-logback-include.xml /var/lib/go-agent/config/agent-launcher-logback-include.xml
COPY agent-logback-include.xml /var/lib/go-agent/config/agent-logback-include.xml

# Setup periodic cleanup of containers and images
COPY docker-gc.sh /usr/bin/docker-gc
COPY docker-gc.cron /etc/cron.d/docker-gc
RUN chmod -c 644 /etc/cron.d/docker-gc && crontab

ENV LC_ALL=C.UTF-8 \
  LANG=C.UTF-8


# https://github.com/just-containers/s6-overlay#customizing-s6-behaviour
# Stop the container if cont-init scripts fail
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
