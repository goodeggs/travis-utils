#!/bin/sh
set -e
# set -x

if [ -z "$CACHE_DIR" ]; then
  CACHE_DIR="~/.docker-compose-cacher"
fi

dcc=$(mktemp -d)

curl -sSL https://github.com/goodeggs/docker-compose-cacher/releases/download/v1.3.0/docker-compose-cacher_v1.3.0_linux_amd64.tar.gz | tar xz -C "$dcc" docker-compose-cacher

"$dcc/docker-compose-cacher" -d "$CACHE_DIR"
docker-compose up -d

