#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

echo "Launching openwrt test image"
echo "From inside container, run: opkg update && opkg install /tmp/torsh/torsh-node_***.ipk"

docker run -v $OUTPUT_DIR:/tmp/torsh/ -it --rm openwrtorg/rootfs:$TARGET_OPENWRT_SDK