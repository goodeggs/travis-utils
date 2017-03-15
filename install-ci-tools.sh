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
      echo 1.11.2 ;;
    docker-compose-cacher)
      echo 1.3.0 ;;
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
    docker-compose-cacher)
      if ! sha_matches docker-compose-cacher "8aae2d21b846afab92f03df535bf91b22579e7d796936fc1031d236a95f94871"; then
        curl -sSL "https://github.com/goodeggs/docker-compose-cacher/releases/download/v${version}/docker-compose-cacher_v${version}_linux_amd64.tar.gz" | tar xz docker-compose-cacher
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
      ;;
    phantomjs)
      if [ ! -x phantomjs ] || [ "$(phantomjs -v)" != "$version" ]; then
        rm -rf phantomjs .phantomjs
        mkdir -p .phantomjs
        curl -sSL "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${version}-linux-x86_64.tar.bz2?t=$(date '+%s')" | tar xj -C .phantomjs --strip 1
        ln -s "$PWD/.phantomjs/bin/phantomjs"
      fi
      ;;
    *)
      echo "ERROR: unknown tool"
      exit 1
  esac
  echo "✔"
done

