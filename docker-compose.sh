#!/bin/sh
set -e
# set -x

if [ -z "$CACHE_DIR" ]; then
  CACHE_DIR="~/.docker-compose-cacher"
fi

curl -sSL https://github.com/goodeggs/docker-compose-cacher/releases/download/v1.2.0/docker-compose-cacher_v1.2.0_linux_amd64.tar.gz | tar xz -C /tmp docker-compose-cacher

/tmp/docker-compose-cacher -d "$CACHE_DIR"
docker-compose up -d

