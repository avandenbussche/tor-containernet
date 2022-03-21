#!/bin/sh

# Per https://github.com/openwrt/docker/issues/76
# and https://forum.openwrt.org/t/running-openwrt-inside-docker-sbin-init-stuck/13774/9
#  we need to disable networking configuration overwriting for Docker container
mkdir -p /var/run
mkdir -p /var/lock
/etc/init.d/network disable
rm /lib/preinit/10_indicate_preinit

echo "src/gz torshrepo http://172.17.0.1:8000/download/openwrt" >> /etc/opkg.conf
opkg-key add /keys/public.key
opkg update
opkg install torsh

exec /sbin/init