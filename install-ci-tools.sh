#!/bin/sh
set -e
#set -x

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
      echo 1.12.0 ;;
    chromedriver)
      echo 2.27 ;;
    yarn)
      echo 0.19.0 ;;
    node)
      echo 6.9.4 ;;
    npm)
      echo 3.9.6 ;;
    phantomjs)
      echo 1.9.8 ;;
    sumotime)
      echo 1.0.1 ;;
    git-crypt)
      echo 0.5.0 ;;
    ranch)
      echo 7.4.0 ;;
    pivotal-deliver)
      echo 2.0.0 ;;
  esac
}

[ -z "$CACHE_DIR" ] && CACHE_DIR="/tmp/ci-tools"
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR" || exit 1

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
        curl -sSL "https://github.com/yarnpkg/yarn/releases/download/v${version}/yarn-v${version}.tar.gz" | tar xz -C .yarn --strip 1
        ln -s "$PWD/.yarn/bin/yarn"
      fi
      # put the yarn cache outside of $CACHE_DIR
      ./yarn config set cache-folder /tmp/yarn-cache
      ;;
    node)
      if [ ! -x node ] || [ "$(./node -v)" != "v${version}" ]; then
        rm -rf node npm .node
        mkdir -p .node
        curl -sSL "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz" | tar xJ -C .node --strip 1
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
      if [ ! -x git-crypt ] || git-crypt --version | egrep -qv "\\b${version}\\b"; then
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
openssl aes-256-cbc -k "\$GITCRYPT_PASS" -in .git-crypt.key.enc -out "\$keyfile" -d
git-crypt unlock "\$keyfile"
rm "\$keyfile"

echo "git-crypt unlocked!"
EOF
      chmod +x git-crypt-unlock
      ;;
    ranch)
      if [ ! -x ranch ] || [ "$(./ranch version)" != "$version" ]; then
        rm -f ranch
        curl -sSL "https://github.com/goodeggs/platform/releases/download/v${version}/ranch-Linux-x86_64" > ranch
        chmod +x ranch
      fi
      ;;
    pivotal-deliver)
      if [ ! -x pivotal-deliver ] || [ "$(./pivotal-deliver -v)" != "$version" ]; then
        rm -f pivotal-deliver
        curl -sSL "https://github.com/goodeggs/pivotal-deliver/releases/download/v${version}/pivotal-deliver-Linux-x86_64" > pivotal-deliver
        chmod +x pivotal-deliver
      fi
      cat > deliver-pivotal-stories <<EOF
#!/bin/sh
set -e
git log --format=full "\$ECRU_LIVE_COMMIT..\$ECRU_COMMIT" | pivotal-deliver
EOF
      chmod +x deliver-pivotal-stories
      ;;
    *)
      echo "ERROR: unknown tool"
      exit 1
  esac
  echo "✔"
done

