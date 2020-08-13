#!/bin/sh
echo "Starting tor in the background"
chown -R root: /etc/tor
tor &
