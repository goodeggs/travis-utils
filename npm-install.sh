#!/bin/sh
set -ex

npm prune
npm cache clean

if test -f ./node_modules/.node-version && [ $(cat ./node_modules/.node-version) != `node -v` ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

travis_retry npm install

echo `node -v` > ./node_modules/.node-version

