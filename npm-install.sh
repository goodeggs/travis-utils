#!/bin/sh
set -eux

# retry 3 times with 10s wait
retry () { for _ in 1 2 3; do "$@" && return 0; sleep 10; done; return 1; }

# install npm 3.9 or whatever
retry npm install -g "npm@${NPM_VERSION:-3.9}"
npm -v

npm prune
npm cache clean

if test -f ./node_modules/.node-version && [ "$(cat ./node_modules/.node-version)" != "$(node -v)" ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

retry npm install

echo `node -v` > ./node_modules/.node-version
