#!/bin/sh
set -ex

# Mostly grifted from: https://github.com/web-animations/web-animations-js/blob/master/.travis-setup.sh

# Make sure /dev/shm has correct permissions.
ls -l /dev/shm
sudo chmod 1777 /dev/shm
ls -l /dev/shm

sudo apt-get update --fix-missing

sudo ln -sf $(which true) $(which xdg-desktop-menu)

CHROME=google-chrome-${CHROME_VERSION:-stable}_current_amd64.deb
curl -Lo $CHROME https://dl.google.com/linux/direct/$CHROME
sudo dpkg --install $CHROME

# versions like "stable" install in /opt/google/chrome, whereas "beta" installs in /opt/google/chrome-beta
if [ -f /opt/google/chrome/chrome-sandbox ]; then
  CHROME_SANDBOX=/opt/google/chrome/chrome-sandbox
else
	CHROME_SANDBOX=$(ls -d /opt/google/chrome*/chrome-sandbox)
fi

# Download a custom chrome-sandbox which works inside OpenVC containers (used on travis).
curl -Lo chrome-standbox https://github.com/goodeggs/travis-utils/raw/master/vendor/chrome-sandbox
sudo install -m 4755 chrome-sandbox $CHROME_SANDBOX

