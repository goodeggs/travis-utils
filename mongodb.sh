#!/bin/sh
set -ex

sudo service mongodb stop || true # stop the mongodb service if it's running so we can bind

mkdir -p /tmp/mongodb/data
cd /tmp/mongodb
curl -Lo mongodb.tgz http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGO_VERSION}.tgz
tar -xvf mongodb.tgz
/tmp/mongodb/mongodb-linux-x86_64-${MONGO_VERSION}/bin/mongod --dbpath /tmp/mongodb/data --bind_ip 127.0.0.1 --auth > /dev/null 2>&1 &

# appears mongodb killed this key on 2016/05/23
#sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
#echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
#sudo apt-get update || true
#sudo apt-get -y install $MONGO_PACKAGE
