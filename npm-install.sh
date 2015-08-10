#!/bin/sh
set -ex

# travis_retry isn't available to sub-scripts
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }

# install npm v2
retry npm install -g npm@2.13.4

npm prune
npm cache clean

if test -f ./node_modules/.node-version && [ $(cat ./node_modules/.node-version) != `node -v` ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

retry npm install

echo `node -v` > ./node_modules/.node-version

