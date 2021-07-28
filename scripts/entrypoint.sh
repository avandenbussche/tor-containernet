#!/bin/sh
echo "Starting tor in the background"
chown -R root: /usr/local/etc/tor
tor &
