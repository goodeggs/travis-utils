#!/bin/sh
set -ex

# install ranch CLI
curl -Ls https://github.com/goodeggs/platform/releases/download/v6.3.0/ranch_6.3.0_linux_amd64.tar.gz | ( cd /tmp && tar xz --strip 1 )

# travis_retry isn't available to sub-scripts
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }

# Prepare for deploy
rm -f Procfile Dockerfile
commit=$ECRU_COMMIT # TODO fall back to parsing from local git repo
SHA=$commit npm run predeploy
echo "module.exports = '$commit';" > ./version.js

# Deploy staging
/tmp/ranch deploy -f .ranch.staging.yaml
/tmp/ranch run -f .ranch.staging.yaml -- npm run postdeploy
smoke_test () { SMOKE_TEST_ENV=staging npm run test:smoke; }
retry smoke_test


## DISABLE PRODUCTION DEPLOYS ###
exit 0
## DISABLE PRODUCTION DEPLOYS ###


# Deploy production
ranch deploy
ranch run npm run postdeploy

# Apply changes to Statsfile, if any.
if [ -f ./Statsfile.coffee ]; then
  is_babel=
  statsfile_hash=$(coffee -e 'console.log(JSON.stringify(require("./Statsfile.coffee")))' | md5sum | cut -d ' ' -f 1)
elif [ -f ./Statsfile.js ]; then
  is_babel=1
  statsfile_hash=$(babel-node -e 'console.log(JSON.stringify(require("./Statsfile.js")))' | md5sum | cut -d ' ' -f 1)
fi
apply_statsfile() {
  if [ ! -z $is_babel ]; then args='--require=babel-register'; fi
  goodeggs-stats $args
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
