#!/bin/sh
set -ex

if [ "$R_VERSION" ]; then
  R_PACKAGE="r-base=${R_VERSION}"
else
  R_PACKAGE="r-base"
fi

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
echo 'deb http://cran.cnr.berkeley.edu/bin/linux/ubuntu precise/' | sudo tee /etc/apt/sources.list.d/r.list
sudo apt-get update
sudo apt-get install $R_PACKAGE

