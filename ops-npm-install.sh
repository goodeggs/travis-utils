#!/bin/sh
set -ex

node -v
npm -v

# travis_retry isn't available to sub-scripts
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }

#
# [bb 5/5/15] - WIP:
# - the caches on ecru and travis are really dumb, just whole saved directories.
# - with only `npm install`, modules removed in shrinkwrap don't get removed from app.
#   `npm install` also does not necessarily update all submodules per shrinkwrap.
# - with `npm prune`, sometimes modules that should be kept, are removed, don't know why.
# - `npn update` in theory makes sure all missing modules are installed,
#   hopefully filling any gaps left from `install` and `prune`.
#
npm cache clean
retry npm install
npm prune
npm update

if test -f ./node_modules/.node-version && [ $(cat ./node_modules/.node-version) != `node -v` ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

# dump module list to compare w/ local, and to spot extraneous.
# but some extraneous (like `local_modules`) are ok, so ignore errors.
npm ls || true

echo `node -v` > ./node_modules/.node-version

