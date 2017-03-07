#!/bin/sh
set -e
set -o pipefail
# set -x

curl -sSL https://github.com/goodeggs/docker-compose-cacher/releases/download/v1.2.0/docker-compose-cacher_v1.2.0_linux_amd64.tar.gz | tar xz -c /tmp docker-compose-cacher

/tmp/docker-compose-cacher
docker-compose up -d

