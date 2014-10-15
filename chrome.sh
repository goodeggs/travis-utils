#!/bin/sh
set -ex

# Mostly grifted from: https://github.com/web-animations/web-animations-js/blob/master/.travis-setup.sh

# Make sure /dev/shm has correct permissions.
ls -l /dev/shm
chmod 1777 /dev/shm
ls -l /dev/shm

apt-get update --fix-missing

sudo ln -sf $(which true) $(which xdg-desktop-menu)

CHROME=google-chrome-${CHROME_VERSION:-stable}_current_amd64.deb
curl -Lo $CHROME https://dl.google.com/linux/direct/$CHROME
dpkg --install $CHROME || apt-get -f install

if [ -f /opt/google/chrome/chrome-sandbox ]; then
  CHROME_SANDBOX=/opt/google/chrome/chrome-sandbox
else
	CHROME_SANDBOX=$(ls /opt/google/chrome*/chrome-sandbox)
fi

# Download a custom chrome-sandbox which works inside OpenVC containers (used on travis).
rm -f $CHROME_SANDBOX
curl -Lo $CHROME_SANDBOX https://github.com/goodeggs/travis-utils/raw/master/vendor/chrome-sandbox
chmod 4755 $CHROME_SANDBOX

