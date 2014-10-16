#!/bin/sh
set -ex

CHROMEDRIVER=chromedriver_linux64.zip
curl -Lo $CHROMEDRIVER http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION:-2.10}/$CHROMEDRIVER
unzip $CHROMEDRIVER
sudo install chromedriver /usr/bin

export DISPLAY=:99.0
sudo -E /etc/init.d/xvfb start
chromedriver "$@" &

