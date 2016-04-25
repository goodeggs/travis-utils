#!/bin/sh
set -ex

if [ "$MONGO_VERSION" ]; then
  MONGO_PACKAGE="mongodb-org=${MONGO_VERSION}"
else
  MONGO_PACKAGE="mongodb-org"
fi

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update || true
sudo apt-get -y install $MONGO_PACKAGE

