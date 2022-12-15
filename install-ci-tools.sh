#!/bin/sh
set -e

sha_matches () {
  tool="$1"
  expected_sha="$2"
  [ -x "./$tool" ] || return 1
  actual_sha=$(shasum -a 256 "./$tool" | awk '{print $1}')
  [ "$expected_sha" = "$actual_sha" ] || return 1
  return 0
}

split () {
  str=$1 sep=$2 sub=""
  shift 2
  until test $# = 0; do
    sub=${str%%[$sep]*}; str=${str#$sub}; str=${str#[$sep]}
    eval "$1"='$sub'; shift
  done
}

blessed_version () {
  tool=$1
  case $tool in
    docker-compose)
      echo 1.24.0 ;;
    chromedriver)
      echo 2.43 ;;
    yarn)
      echo 1.9.4 ;;
    node)
      echo 14.16.0 ;;
    npm)
      echo 3.9.6 ;;
    phantomjs)
      echo 2.1.1 ;;
    sumotime)
      echo 1.0.1 ;;
    git-crypt)
      echo 0.6.0 ;;
    ranch)
      echo 10.8.0 ;;
    packer)
      echo 1.0.3 ;;
    direnv)
      echo 2.15.2 ;;
    go)
      echo 1.10.1 ;;
    mbt)
      echo 0.21.0 ;;
    aws)
      echo 1.16.232 ;;
    git-crypt-keeper)
      echo a8ce476 ;;
    codecov)
      echo 1.0.6 ;;
  esac
}

[ -z "$CACHE_DIR" ] && CACHE_DIR="/tmp/ci-tools"
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR" || exit 1
PATH=${CACHE_DIR}:${PATH}

for arg in "$@"; do
  split "$arg" '=@' tool version
  [ -z "$version" ] && version=$(blessed_version "$tool")
  printf "%s " "$tool@$version"

  case "$tool" in
    docker-compose)
      if [ ! -x docker-compose ] || ./docker-compose -v | egrep -qv "\\b${version}\\b"; then
        curl -sSL "https://github.com/docker/compose/releases/download/${version}/docker-compose-Linux-x86_64" > docker-compose
        chmod +x docker-compose
      fi
      ;;
    chromedriver)
      if [ ! -x chromedriver ] || ./chromedriver -v | egrep -qv "\\b${version}\\b"; then
        curl -sSLo tmp.zip "http://chromedriver.storage.googleapis.com/${version}/chromedriver_linux64.zip"
        unzip -qqo tmp.zip chromedriver
        rm -rf tmp.zip
      fi
      cat > start-chromedriver <<EOF
#!/bin/sh
set -e
export DISPLAY=:99.0
sh /etc/init.d/xvfb start || true
chromedriver "\$@" &
EOF
      chmod +x start-chromedriver
      ;;
    yarn)
      if [ ! -x yarn ] || [ "$(./yarn -V)" != "$version" ]; then
        rm -rf yarn .yarn
        mkdir -p .yarn
        curl --retry 3 -sSL "https://github.com/yarnpkg/yarn/releases/download/v${version}/yarn-v${version}.tar.gz" | tar xz -C .yarn --strip 1
        ln -s "$PWD/.yarn/bin/yarn"
      fi
      # put the yarn cache outside of $CACHE_DIR
      ./yarn config set cache-folder /tmp/yarn-cache
      # workaround for https://github.com/yarnpkg/yarn/issues/2429
      ./yarn config set child-concurrency 1
      ;;
    node)
      if [ ! -x node ] || [ "$(./node -v)" != "v${version}" ]; then
        rm -rf node npm .node
        mkdir -p .node
        curl --retry 3 -sSL "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz" | tar xJ -C .node --strip 1
        ln -s "$PWD/.node/bin/node"
        ln -s "$PWD/.node/bin/npm"
      fi
      ;;
    npm)
      if [ "$(npm -v)" != "$version" ]; then
        npm install -g --progress=false "npm@$version" 1>/dev/null
      fi
      cat > better-npm-install <<EOF
#!/bin/sh
set -e

# retry 3 times with 10s wait
retry () { for _ in 1 2 3; do "\$@" && return 0; sleep 10; done; return 1; }

npm prune
npm cache clean

if test -f ./node_modules/.node-version && [ "\$(cat ./node_modules/.node-version)" != "\$(node -v)" ]; then
  echo "Node version changed since last build; rebuilding dependencies"
  npm rebuild
fi

retry npm install --unsafe-perm

node -v > ./node_modules/.node-version
EOF
      chmod +x better-npm-install
      ;;
    phantomjs)
      if [ ! -x phantomjs ] || [ "$(phantomjs -v)" != "$version" ]; then
        rm -rf phantomjs .phantomjs
        mkdir -p .phantomjs
        curl -sSL "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${version}-linux-x86_64.tar.bz2?t=$(date '+%s')" | tar xj -C .phantomjs --strip 1
        ln -s "$PWD/.phantomjs/bin/phantomjs"
      fi
      ;;
    sumotime)
      if [ ! -x sumotime ] || [ "$(./sumotime -v)" != "$version" ]; then
        rm -rf sumotime
        curl -sSL "https://github.com/goodeggs/sumotime/releases/download/v${version}/sumotime-Linux-x86_64" > sumotime
        chmod +x sumotime
      fi
      ;;
    git-crypt)
      if [ ! -x git-crypt ] || git-crypt --version 2>&1 | egrep -qv "\\b${version}\\b"; then
        # we'll assume this is already installed?
        #sudo apt-get install -y libssl-dev
        tmpdir=$(mktemp -d)
        (
          set -e
          cd "$tmpdir"
          curl -ssL "https://github.com/AGWA/git-crypt/archive/${version}.tar.gz" | tar xz --strip 1
          make
        )
        cp -p "$tmpdir/git-crypt" .
      fi
      cat > git-crypt-unlock <<EOF
#!/bin/sh
set -e
[ -z "\$GITCRYPT_PASS" ] && ( echo "please set GITCRYPT_PASS" ; exit 1 )
[ -f .git-crypt.key.enc ] || ( echo ".git-crypt.key.enc not found or not readable" ; exit 1 )

keyfile=\$(mktemp)
openssl aes-256-cbc -k "\$GITCRYPT_PASS" -in .git-crypt.key.enc -out "\$keyfile" -d -md md5 || openssl aes-256-cbc -k "\$GITCRYPT_PASS" -in .git-crypt.key.enc -out "\$keyfile" -d
git-crypt unlock "\$keyfile"
rm "\$keyfile"

echo "git-crypt unlocked!"
EOF
      chmod +x git-crypt-unlock
      cat > envfile <<EOF
#!/usr/bin/env bash
while read -r line; do
  k=\$(sed 's/=.*$//' <<<"\$line")
  if grep -q '=' <<< "\$line"; then
    v=\$(sed -E 's/^[^=]+=//' <<<"\$line")
  else
    eval "v=\\"\\$\$k\\""
  fi
  echo "export \$k='\$(sed "s/'/'\\"'\\"'/g" <<<"\$v")'"
done < <(grep -E -v '^\\s*(#|$)' "\$1")
EOF
      chmod +x envfile
      ;;
    git-crypt-keeper)
      rm -f git-crypt-keeper
      curl -fsSLo git-crypt-keeper "https://github.com/goodeggs/homebrew-devops/raw/$version/git-crypt-keeper"
      chmod +x git-crypt-keeper
      ;;
    ranch)
      if [ ! -x ranch ] || [ "$(./ranch version)" != "$version" ]; then
        rm -f ranch ranch_real
        curl -fsSL "http://ranch-updates.goodeggs.com/stable/ranch/${version}/linux-amd64.gz" | gunzip > ranch_real
        chmod +x ranch_real
        curl -fsSLo ranch "http://ranch-updates.goodeggs.com/stable/ranch/${version}/ranch-wrapper.sh"
        chmod +x ranch
      fi
      ;;
    packer)
      if [ ! -x packer ] || ./packer -v | egrep -qv "\\b${version}\\b"; then
        curl -sSLo tmp.zip "https://releases.hashicorp.com/packer/${version}/packer_${version}_linux_amd64.zip"
        unzip -qqo tmp.zip packer
        rm -rf tmp.zip
      fi
      ;;
    direnv)
      if [ ! -x direnv ] || [ "$(./direnv version)" != "$version" ]; then
        rm -f direnv
        curl -sSL "https://github.com/direnv/direnv/releases/download/v${version}/direnv.linux-amd64" > direnv
        chmod +x direnv
      fi
      ;;
    mbt)
      if [ ! -x mbt ] || [ "$(./mbt version)" != "$version" ]; then
        rm -f mbt
        curl -sSL "https://dl.bintray.com/buddyspike/bin/mbt_linux_x86_64/${version}/${version}/mbt_linux_x86_64" > mbt
        chmod +x mbt
      fi
      ;;
    go)
      if [ ! -x go ] || [ "$(cat ./.go/.version)" != "${version}" ]; then
        rm -rf go godoc gofmt .go
        mkdir -p .go
        curl -sSL "https://dl.google.com/go/go${version}.linux-amd64.tar.gz" | tar xz -C .go --strip 1
        cat > go <<EOF
#!/bin/sh
export GOROOT=$PWD/.go
export PATH="\$GOROOT/bin:\$PATH"
\$GOROOT/bin/go "\$@"
EOF
        cat > godoc <<EOF
#!/bin/sh
export GOROOT=$PWD/.go
export PATH="\$GOROOT/bin:\$PATH"
\$GOROOT/bin/godoc "\$@"
EOF
        cat > gofmt <<EOF
#!/bin/sh
export GOROOT=$PWD/.go
export PATH="\$GOROOT/bin:\$PATH"
\$GOROOT/bin/gofmt "\$@"
EOF
        chmod +x go godoc gofmt
        echo "$version" > ./.go/.version
      fi
      ;;
    aws)
      if [ ! -x aws ] || ./aws --version | egrep -qv "\\b${version}\\b"; then
        rm -rf aws .aws
        mkdir -p .aws
        curl -sSLo tmp.zip "https://s3.amazonaws.com/aws-cli/awscli-bundle-${version}.zip"
        unzip -qqo tmp.zip
        ./awscli-bundle/install -i $PWD/.aws -b $PWD/aws
        rm -rf awscli-bundle
        rm -rf tmp.zip
      fi
      ;;
    codecov)
      if [ ! -x codecov ] || ! ./codecov -h | egrep -q "\\b${version}\\b"; then
        rm -rf codecov
        curl -Lso codecov "https://github.com/codecov/codecov-bash/raw/${version}/codecov"
        chmod +x codecov
      fi
      ;;
    *)
      echo "ERROR: unknown tool"
      exit 1
  esac
  echo "✔"
done
