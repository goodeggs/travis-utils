#!/bin/sh
set -ex

# travis_retry isn't available to sub-scripts
retry () { for _ in 1 2 3; do if "$@"; then return; else sleep 10; fi; done; exit 1; }

# Prepare for deploy
commit=$BUILDKITE_COMMIT
[ -n "$commit" ] || commit=$ECRU_COMMIT
[ -n "$commit" ] || commit=$(git rev-parse HEAD)

SHA=$commit npm run predeploy
echo "module.exports = '$commit';" > ./version.js

STAGING_RANCH_FILE='.ranch.staging.yaml'
PRODUCTION_RANCH_FILE=$([ -f '.ranch.production.yaml' ] && echo '.ranch.production.yaml' || echo '.ranch.yaml')

# Deploy staging
if [ -f "$STAGING_RANCH_FILE" ]; then
  ranch deploy -f "$STAGING_RANCH_FILE"
  ranch run -f "$STAGING_RANCH_FILE" -- npm run postdeploy
  smoke_test () { SMOKE_TEST_ENV=staging npm run test:smoke; }
  retry smoke_test
else
  echo "WARNING: $STAGING_RANCH_FILE not found, skipping staging deploy..."
fi

if [ "$DEPLOY_PRODUCTION" = "1" ]; then
  # Deploy production
  ranch deploy -f "$PRODUCTION_RANCH_FILE"
  ranch run -f "$PRODUCTION_RANCH_FILE" -- npm run postdeploy
else
  echo "DEPLOY_PRODUCTION env var is not set to 1. Not deploying to production."
fi

# Apply changes to Statsfile, if any.
if [ -f ./Statsfile.js ]; then
  # NOTE: importing Statsfile may import some app modules and log things, so we hash only on the last logged line
  # For example, apps are known to log "STATUS_API_TOKEN required, but not set. Configuring goodeggs-status in simulate mode"
  # within a full JSON log line with a timestamp - which makes this hashing nondeterministic. :(
  statsfile_hash=$(babel-node -e 'console.log(JSON.stringify(require("./Statsfile.js")))' | tail -1 | md5sum | cut -d ' ' -f 1)
fi
apply_statsfile() {
  # Assume babel 6 if not overriden. Someday we should remove this.
  DEFAULT_GOODEGGS_STATS_ARGS='--require=babel-register'
  args=${GOODEGGS_STATS_ARGS-$DEFAULT_GOODEGGS_STATS_ARGS}
  # shellcheck disable=SC2086
  goodeggs-stats $args
  if [ ! -d ./.goodeggs-stats-state ]; then mkdir ./.goodeggs-stats-state; fi
  echo "$statsfile_hash" > ./.goodeggs-stats-state/md5_hash
}
if [ ! -f ./.goodeggs-stats-state/md5_hash ]; then
  echo 'No cached Statsfile hash; applying it'
  apply_statsfile
else
  prev_statsfile_cache=$(cat ./.goodeggs-stats-state/md5_hash)
  if [ "$statsfile_hash" != "$prev_statsfile_cache" ]; then
    echo 'Statsfile changed since last deploy; applying it'
    apply_statsfile
  else
    echo 'Statsfile unchanged since last deploy'
  fi
fi
