#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

echo "Working in directory $ROOT_DIR"
echo "Building OpenWrt ipk using SDK $TARGET_OPENWRT_SDK for architecture $TARGET_OPENWRT_ARCH"

OPENWRT_ARCH_FAMILY="${TARGET_OPENWRT_SDK%%-2*}" # -2 is cheating way of extracting everything before version number -21.02 (for example) 
echo "Extracted architecture family name $OPENWRT_ARCH_FAMILY from SDK name"

docker run --rm -v $STAGING_DIR/openwrt/bin/:/home/build/openwrt/bin/ \
				-v $ROOT_DIR/torsh-openwrt-pkg/:/home/build/openwrt/package/torsh/ \
				--network="host" -it openwrtorg/sdk:$TARGET_OPENWRT_SDK /bin/bash -c "\
						./scripts/feeds update base && \
						make defconfig && \
						./scripts/feeds install torsh && \
						sudo make package/torsh/compile -j1 V=s"