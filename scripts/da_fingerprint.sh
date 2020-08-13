#!/bin/sh
# from https://github.com/antitree/private-tor-network/blob/master/scripts/da_fingerprint
# version 2
set -e
NODE_DIR=$1
NICKNAME=$(grep "^Nickname" "$NODE_DIR/torrc" | awk '{print $2}')
OR_PORT=$(grep "^Orport" "$NODE_DIR/torrc" | awk '{print $2}')
AUTH=$(grep "^fingerprint" "$NODE_DIR/keys/authority_certificate" | awk '{print $2}')
DIR_ADDR=$(grep "^dir-address" "$NODE_DIR/keys/authority_certificate" | awk '{print $2}')
FINGERPRINT=$(awk '{print $2}' "$NODE_DIR/fingerprint")

echo "DirAuthority $NICKNAME orport=$OR_PORT no-v2 v3ident=$AUTH $DIR_ADDR $FINGERPRINT"
