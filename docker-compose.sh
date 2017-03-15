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
  full_cache="-1"
  docker-compose pull
else
  echo "using docker-compose-cacher"

  if [ -z "$CACHE_DIR" ]; then
    CACHE_DIR="$HOME/.docker-compose-cacher"
  fi

  mkdir -p "$CACHE_DIR"

  if [ ! -x "$CACHE_DIR/docker-compose-cacher" ] || [ "$(shasum -a 256 "$CACHE_DIR/docker-compose-cacher" | awk '{print $1}')" != "8aae2d21b846afab92f03df535bf91b22579e7d796936fc1031d236a95f94871" ]; then
    full_cache="0"
    curl -sSL https://github.com/goodeggs/docker-compose-cacher/releases/download/v1.3.0/docker-compose-cacher_v1.3.0_linux_amd64.tar.gz | tar xz -C "$CACHE_DIR" docker-compose-cacher
  else
    full_cache="1"
  fi
  
  "$CACHE_DIR/docker-compose-cacher" -d "$CACHE_DIR"
fi

end=$(date "+%s")
duration=$(( end - start ))
curl -sS -XPOST -d "docker-compose-cacher experiment results caching=${caching} full_cache=${full_cache} duration=${duration}" "$SUMO_ENDPOINT"

timeout 1m docker-compose up -d
if [ "$?" -eq 124 ]; then
  echo "docker-compose timed out... killing build."
  curl -sS -XPOST -d "docker-compose timeout" "$SUMO_ENDPOINT"
  exit 1
fi

