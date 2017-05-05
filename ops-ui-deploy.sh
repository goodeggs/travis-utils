#!/bin/sh
set -ex

# Assert required env variables are defined
: "${ECRU_COMMIT:?must be set}"
: "${S3_STAGING_BUCKET:?must be set}"
: "${S3_PRODUCTION_BUCKET:?must be set}"
: "${AWS_DEFAULT_REGION:?must be set}"
: "${AWS_ACCESS_KEY_ID:?must be set}"
: "${AWS_SECRET_ACCESS_KEY:?must be set}"

deploy_to_s3 () {
  bucket=$1
  aws s3 cp --acl=public-read build s3://${bucket}/ --recursive --exclude "index.html"
  aws s3 cp --acl=public-read build/index.html s3://${bucket}/
}

# Write version.js
commit=$ECRU_COMMIT
echo "module.exports = '$commit';" > ./version.js

# Deploy to staging
SHA=$commit NODE_ENV=production BUILD_ENV=production APP_INSTANCE=staging npm run predeploy
deploy_to_s3 $S3_STAGING_BUCKET
FASTLY_SERVICE=$STAGING_FASTLY_SERVICE npm run postdeploy

# Abort if not deploying to production
if [ "$DEPLOY_PRODUCTION" != 1 ]
then
  echo 'STOPPING AT STAGING. Toggle `env.DEPLOY_PRODUCTION` to go all the way.'
  exit 0
fi

# Smoke tests
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }
smoke_test () { SMOKE_TEST_ENV=staging npm run test:smoke; }
retry smoke_test

# Deploy to production
SHA=$commit NODE_ENV=production BUILD_ENV=production APP_INSTANCE=production npm run predeploy
deploy_to_s3 $S3_PRODUCTION_BUCKET
FASTLY_SERVICE=$PRODUCTION_FASTLY_SERVICE npm run postdeploy
