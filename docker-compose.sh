#!/bin/sh
set -e
# set -x

if [ -z "$SUMO_ENDPOINT" ]; then
  echo "must provide SUMO_ENDPOINT"
  exit 1
fi

start=$(date "+%s")

caching=$(grep -m1 -ao '[0-1]' /dev/urandom | head -n1)
if [ "$caching" == "0" ]; then
  echo "skipping docker-compose-cacher"
else
  echo "using docker-compose-cacher"

  if [ -z "$CACHE_DIR" ]; then
    CACHE_DIR="~/.docker-compose-cacher"
  fi

  dcc=$(mktemp -d)
  
  curl -sSL https://github.com/goodeggs/docker-compose-cacher/releases/download/v1.3.0/docker-compose-cacher_v1.3.0_linux_amd64.tar.gz | tar xz -C "$dcc" docker-compose-cacher
  
  "$dcc/docker-compose-cacher" -d "$CACHE_DIR"
fi

docker-compose up -d

end=$(date "+%s")
duration=$(( $end - $start ))

curl -sS -XPOST -d "docker-compose-cacher experiment results caching=${caching} duration=${duration}" "$SUMO_ENDPOINT"

