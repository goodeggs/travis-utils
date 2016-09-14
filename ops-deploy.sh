#!/bin/sh
set -ex

# travis_retry isn't available to sub-scripts
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }

# Prepare for deploy
rm -f Procfile Dockerfile
npm run predeploy

# Deploy staging
ranch deploy -f .ranch.staging.yaml
ranch run -f .ranch.staging.yaml -- npm run postdeploy
retry 'SMOKE_TEST_ENV=staging npm run test:smoke'

# Deploy production
ranch deploy
ranch run npm run postdeploy

# Apply changes to Statsfile, if any.
if [ -f ./Statsfile.coffee ]; then
  is_babel=
  statsfile_hash=$(coffee -e 'console.log(require("./Statsfile.coffee"))' | md5sum)
elif [ -f ./Statsfile.js ]; then
  is_babel=1
  statsfile_hash=$(babel-node -e 'console.log(require("./Statsfile.js"))' | md5sum)
fi
apply_statsfile() {
  if [ ! -z $is_babel ]; then args='--require=babel-register'; fi
  APP_NAME=pick-api goodeggs-stats $args # FIXME
  if [ ! -d ./.goodeggs-stats-state ]; then mkdir ./.goodeggs-stats-state; fi
  echo $statsfile_hash > ./.goodeggs-stats-state/md5_hash
}
if [ ! -f ./.goodeggs-stats-state/md5_hash ]; then
  echo 'No cached Statsfile hash; applying it'
  apply_statsfile
else
  prev_statsfile_cache=$(cat ./.goodeggs-stats-state/md5_hash)
  if [ $statsfile_hash != $prev_statsfile_cache ]; then
    echo 'Statsfile changed since last deploy; applying it'
    apply_statsfile
  else
    echo 'Statsfile unchanged since last deploy'
  fi
fi