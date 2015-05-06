#!/bin/sh
set -ex

# environment info
node -v
npm -v
npm config get cache   # show dir
npm cache ls | wc -l   # dumb count. (too many lines to fully dump)

# travis_retry isn't available to sub-scripts
retry () { for i in 1 2 3; do "$@" && return || sleep 10; done; exit 1; }

#
# [bb 5/5/15] - WIP:
# - the caches on ecru and travis are really dumb, just whole saved directories.
# - with only `npm install`, modules removed in shrinkwrap don't get removed from app.
#   `npm install` also does not necessarily update all submodules per shrinkwrap.
# - with `npm prune`, sometimes modules that should be kept, are removed, don't know why.
# - `npm update` in theory makes sure all missing modules are installed,
#   hopefully filling any gaps left from `install` and `prune`.
# - but `npm update` doesn't run aperture (for symlinks)... oy.
#
retry npm cache clean
retry npm prune
retry npm install
retry npm update

if test -f ./node_modules/.node-version && [ $(cat ./node_modules/.node-version) != `node -v` ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

# dump module list to compare w/ local, and to spot extraneous.
# but some extraneous (like `local_modules`) are ok, so ignore errors.
npm ls || true

echo `node -v` > ./node_modules/.node-version

