#!/bin/sh
set -ex

CHROMEDRIVER=chromedriver_linux64.zip
curl -Lo $CHROMEDRIVER http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION:-2.43}/$CHROMEDRIVER
unzip $CHROMEDRIVER

export DISPLAY=:99.0
sh /etc/init.d/xvfb start || true # might already be started

./chromedriver "$@" &
