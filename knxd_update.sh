#!/bin/bash
set -e
# Exit on error
###############################################################################
# Update KNXD if installed with Openhabian
# Florian Schätzig florian@schaetzig.de
# Version 0.1.0 12.08.2020          Florian First Draft
#
# based on https://michlstechblog.info/blog/download/electronic/install_knxd_systemd.sh
# https://michlstechblog.info/blog/raspberry-pi-eibknx-ip-gateway-and-router-with-knxd/
# Script to compile and install knxd on a debian jessie (8) based systems
# Michael Albert info@michlstechblog.info
# Version 0.7.18 26.05.2020         Michael Default Timrout in knxd is changed from 500ms -> 2000ms. Patch removed
###############################################################################
if [ "$(id -u)" != "0" ]; then
   echo "     Attention!!!"
   echo "     Start script must run as root" 1>&2
   echo "     Start a root shell with"
   echo "     sudo su -"
   exit 1
fi
# define environment
export BUILD_PATH=$HOME/knxdbuild
export BUSSDK_PATH=${BUILD_PATH}/bussdk
export INSTALL_PREFIX=/usr/local

# stop KNXD
systemctl stop knxd.service

# Requiered packages
apt-get update 
apt-get -y upgrade
apt-get -y install build-essential cmake
apt-get -y install automake autoconf libtool 
apt-get -y install git 
apt-get -y install debhelper cdbs 
apt-get -y install libsystemd-dev libsystemd0 pkg-config libusb-dev libusb-1.0-0-dev
apt-get -y install libev-dev 
apt-get -y install setserial

# Add /usr/local library to libpath
export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH
if [ ! -d "$BUILD_PATH" ]; then mkdir -p "$BUILD_PATH"; fi

cd $BUILD_PATH
if [ -d "$BUILD_PATH/knxd" ]; thencd knxd
	echo "knxd repository found"
	cd "$BUILD_PATH/knxd"
	git pull
else
	git clone https://github.com/knxd/knxd knxd
	cd knxdcd
fi

git checkout master

#git checkout master
# All previously installed libraries have to be removed
set +e
rm $INSTALL_PREFIX/lib/libeibclient* > /dev/null 2>&1
set -e

bash bootstrap.sh

./configure \
    --enable-tpuart \
    --enable-ft12 \
	--enable-dummy \
    --enable-eibnetip \
    --enable-eibnetserver \
	--disable-systemd \
	--enable-busmonitor \
    --enable-eibnetiptunnel \
    --enable-eibnetipserver \
    --enable-groupcache \
    --enable-usb \
    --prefix=$INSTALL_PREFIX \
	CPPFLAGS="-I$BUILD_PATH/fmt"
# For USB Debugging add -DENABLE_LOGGING=1 and -DENABLE_DEBUG_LOGGING=1 to CFLAGS and CPPFLAGS:
# 	CFLAGS="-static -static-libgcc -static-libstdc++ -DENABLE_LOGGING=1 -DENABLE_DEBUG_LOGGING=1" \
#	CPPFLAGS="-static -static-libgcc -static-libstdc++ -DENABLE_LOGGING=1 -DENABLE_DEBUG_LOGGING=1" 
make clean && make && make install

#start KNXD
systemctl start knxd.service
systemctl status knxd.service
knxd --version
echo "DONE"