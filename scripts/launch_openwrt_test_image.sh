#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

OPENWRT_VERSION="21.02.1"

ARCH="${RUST_TARGET_ARCH/"unknown"/"openwrt"}"		# e.g. x86_64-openwrt-linux-musl
ARCH_FAMILY="${ARCH%%-*}"                         	# e.g. x86_64
ARCH_IMAGE_TAG="$ARCH_FAMILY-$OPENWRT_VERSION"     	# e.g. x86_64-21.02.1

echo "Launching openwrt test image"
echo "From inside container, run: opkg update && opkg install /tmp/torsh/torsh-node_***.ipk"

docker run -v $OUTPUT_DIR:/tmp/torsh/ -it --rm openwrtorg/rootfs:$ARCH_IMAGE_TAG