#!/bin/sh
set -ex

# TODO(bobzoller): remove FASTLY things once all UI sites are migrated to Cloudflare

# Assert required env variables are defined
commit=${BUILDKITE_COMMIT:-$ECRU_COMMIT}
: "${commit:?must be set}"
: "${S3_PRODUCTION_BUCKET:?must be set}"
: "${AWS_DEFAULT_REGION:?must be set}"
: "${AWS_ACCESS_KEY_ID:?must be set}"
: "${AWS_SECRET_ACCESS_KEY:?must be set}"

deploy_to_s3 () {
  bucket=$1
  aws s3 cp --acl public-read --cache-control public,max-age=31536000 build s3://${bucket}/ --recursive --exclude "index.html"
  aws s3 cp --acl public-read --cache-control public,max-age=31536000 build/index.html s3://${bucket}/
}

# Write version.js
echo "module.exports = '$commit';" > ./version.js

# Deploy to staging, if necessary. Set `NO_STAGING` to `1` if no staging environment.
if [ "$NO_STAGING" = 1 ]
then
  echo 'No staging environment. Skipping deploy to staging and smoke test.'
else
  : "${S3_STAGING_BUCKET:?must be set}"
  SHA=$commit NODE_ENV=production BUILD_ENV=production APP_INSTANCE=staging yarn run predeploy
  deploy_to_s3 $S3_STAGING_BUCKET
  FASTLY_SERVICE=$STAGING_FASTLY_SERVICE NODE_ENV=production APP_INSTANCE=staging yarn run postdeploy

  # Smoke tests
  retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }
  smoke_test () { SMOKE_TEST_ENV=staging yarn run test:smoke; }
  retry smoke_test
fi

# Abort if not deploying to production
if [ "$DEPLOY_PRODUCTION" != 1 ]
then
  echo 'STOPPING AT STAGING. Toggle `env.DEPLOY_PRODUCTION` to go all the way.'
  exit 0
fi

# Deploy to production
SHA=$commit NODE_ENV=production BUILD_ENV=production APP_INSTANCE=production yarn run predeploy
deploy_to_s3 $S3_PRODUCTION_BUCKET
FASTLY_SERVICE=$PRODUCTION_FASTLY_SERVICE NODE_ENV=production APP_INSTANCE=production yarn run postdeploy
