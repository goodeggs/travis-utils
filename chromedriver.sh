#!/bin/sh
set -ex

CHROMEDRIVER=chromedriver_linux64.zip
curl -Lo $CHROMEDRIVER http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION:-2.15}/$CHROMEDRIVER
unzip $CHROMEDRIVER

export DISPLAY=:99.0
sh -e /etc/init.d/xvfb start
./chromedriver "$@" &
