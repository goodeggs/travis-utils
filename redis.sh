#!/bin/sh
set -ex

if [ "$REDIS_VERSION" ]; then
  REDIS_PACKAGE="redis=${REDIS_VERSION}"
else
  REDIS_PACKAGE="redis"
fi

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv C7917B12
echo "deb http://ppa.launchpad.net/chris-lea/redis-server/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis-server.list
sudo apt-get update || true
sudo apt-get install $REDIS_PACKAGE

