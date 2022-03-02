#!/bin/sh

# Per https://github.com/openwrt/docker/issues/76
# and https://forum.openwrt.org/t/running-openwrt-inside-docker-sbin-init-stuck/13774/9
#  we need to disable networking configuration overwriting for Docker container
mkdir -p /var/run
mkdir -p /var/lock
/etc/init.d/network disable
rm /lib/preinit/10_indicate_preinit

opkg update

exec /sbin/init