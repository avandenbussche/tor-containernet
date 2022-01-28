#!/bin/sh

WORKDIR=/usr/local/etc/tor

# Check whether torrc exists
if [ -f "$WORKDIR/torrc" ]; then
    echo "Found torrc"
else
    echo "Couldn't find torrc"
fi

# Start Tor
echo "Starting Tor in the background"
chown -R root: $WORKDIR
tor &

echo "Starting TorSH in the background"
chmod +x $WORKDIR/torsh-launch.sh
$WORKDIR/torsh-launch.sh