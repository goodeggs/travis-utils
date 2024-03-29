#!/bin/sh
set -ex

# Mostly grifted from: https://github.com/web-animations/web-animations-js/blob/master/.travis-setup.sh

# Make sure /dev/shm has correct permissions.
ls -l /dev/shm
sudo chmod 1777 /dev/shm
ls -l /dev/shm

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update --fix-missing || true
sudo apt-get -y install dpkg || true

sudo ln -sf $(which true) $(which xdg-desktop-menu)

CHROME_VERSION="${CHROME_VERSION:-current}"
CHROME="google-chrome-stable_${CHROME_VERSION}_amd64.deb"
curl -Lo "${CHROME}" "https://dl.google.com/linux/direct/${CHROME}"
if ! sudo dpkg --install "${CHROME}"; then
  sudo apt-get -y --fix-broken install
fi

# versions like "stable" install in /opt/google/chrome, whereas "beta" installs in /opt/google/chrome-beta
if [ -f /opt/google/chrome/chrome-sandbox ]; then
  CHROME_SANDBOX=/opt/google/chrome/chrome-sandbox
else
  CHROME_SANDBOX=$(ls -d /opt/google/chrome*/chrome-sandbox)
fi

# Download a custom chrome-sandbox which works inside OpenVC containers (used on travis).
curl -Lo chrome-sandbox https://github.com/goodeggs/travis-utils/raw/master/vendor/chrome-sandbox
sudo install -m 4755 chrome-sandbox "${CHROME_SANDBOX}"

export DISPLAY=:99
if ! [ -x /run/systemd/system ]; then
  sh /etc/init.d/xvfb start || true # might already be started
else
  sudo systemctl start xvfb # systemctl will not error if already started
fi
