#!/bin/sh
set -ex

CHROMEDRIVER=chromedriver_linux64.zip

# See http://chromedriver.chromium.org/downloads/version-selection.
if ! which google-chrome; then
  echo "Must have google-chrome installed to determine default version of chromedriver to install."
  exit 1
fi
CHROME_VERSION=$(google-chrome --version | grep -oE "[0-9]+.[0-9]+.[0-9]+")
DEFAULT_CHROMEDRIVER_VERSION=$(curl https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION)

curl -Lo $CHROMEDRIVER http://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION:-$DEFAULT_CHROMEDRIVER_VERSION}/$CHROMEDRIVER
unzip $CHROMEDRIVER

export DISPLAY=:99.0
sh /etc/init.d/xvfb start || true # might already be started

./chromedriver "$@" &
