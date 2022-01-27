#!/bin/sh

echo "Starting TorSH node in the background"
/torsh/torsh-bin/target/debug/torsh-node --socket-path /torsh/torsh.sock --whitelist-dir /torsh/whitelist &

echo "Found following torrc configuration:"
cat /usr/local/etc/tor/torrc

echo "Starting Tor in the background"
chown -R root: /usr/local/etc/tor
tor &
