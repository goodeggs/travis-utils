#!/bin/sh
set -ex

REDIS_SERVER_PACKAGE="redis"
REDIS_TOOLS_PACKAGE="redis-tools"

if [ "$REDIS_VERSION" ]; then
  REDIS_SERVER_PACKAGE+="=${REDIS_VERSION}"
  REDIS_TOOLS_PACKAGE+="=${REDIS_VERSION}"
fi

echo $REDIS_SERVER_PACKAGE
echo $REDIS_TOOLS_PACKAGE
exit 0

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv C7917B12
echo "deb http://ppa.launchpad.net/chris-lea/redis-server/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis-server.list
sudo apt-get update || true
sudo apt-get install $REDIS_SERVER_PACKAGE $REDIS_TOOLS_PACKAGE

