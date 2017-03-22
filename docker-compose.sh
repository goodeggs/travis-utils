#!/bin/sh
set -e
# set -x

if [ -z "$SUMO_ENDPOINT" ]; then
  echo "must provide SUMO_ENDPOINT"
  exit 1
fi

debug() {
  echo "+$*"
  "$@"
}

total_start=$(date "+%s")
repo=$(basename "$(git remote get-url origin)" .git)

pull_start=$(date "+%s")
if docker-compose help pull | grep -q -- "--parallel"; then
  debug docker-compose pull --parallel
else
  debug docker-compose pull
fi
pull_end=$(date "+%s")
pull_t=$(( pull_end - pull_start ))

up_start=$(date "+%s")
debug docker-compose up -d
up_end=$(date "+%s")
up_t=$(( up_end - up_start ))

total_end=$(date "+%s")
total_t=$(( total_end - total_start ))

msg=$(cat <<-EOF
{"msg":"ci timing","module":"docker-compose","repo":"${repo}","pull":${pull_t},"up":${up_t},"total":${total_t}}
EOF
)
curl -sS -m10 -XPOST -d "$msg" "$SUMO_ENDPOINT" || true

