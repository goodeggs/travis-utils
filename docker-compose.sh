#!/bin/sh
set -e
# set -x

if [ -z "$SUMO_ENDPOINT" ]; then
  echo "must provide SUMO_ENDPOINT"
  exit 1
fi

start=$(date "+%s")

caching=$(grep -m1 -ao '[0-1]' /dev/urandom | head -n1)
if [ "$caching" = "0" ]; then
  echo "using docker-compose pull"
  docker-compose pull
else
  echo "using docker-compose-cacher"
  if [ -z "$CACHE_DIR" ]; then
    CACHE_DIR="$HOME/.docker-compose-cacher"
  fi
  mkdir -p "$CACHE_DIR"
  docker-compose-cacher -d "$CACHE_DIR"
fi

end=$(date "+%s")
duration=$(( end - start ))
curl -sS -XPOST -d "docker-compose-cacher experiment results caching=${caching} duration=${duration}" "$SUMO_ENDPOINT"

timeout 1m docker-compose up -d
if [ "$?" -eq 124 ]; then
  echo "docker-compose timed out... killing build."
  curl -sS -XPOST -d "docker-compose timeout" "$SUMO_ENDPOINT"
  exit 1
fi

echo "docker-compose is up"

