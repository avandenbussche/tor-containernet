#!/bin/sh

WORKDIR=/usr/local/etc/tor

# Check whether torrc exists
if [ -f "$WORKDIR/torrc" ]; then
    echo "Found torrc"
else
    echo "Couldn't find torrc"
fi

# Create Torsh user
echo "Creating tor user"
useradd tor -G sudo,root

# Update folder ownership permissions
echo "Updating folder permissions"
sudo chown -R tor: $WORKDIR

# Start Tor
echo "Starting Tor in the background"
sudo -u tor tor &

echo "Starting TorSH in the background"
chmod +x $WORKDIR/torsh-launch.sh
$WORKDIR/torsh-launch.sh