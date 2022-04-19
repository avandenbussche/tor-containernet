#!/bin/bash

STAGING_DIR=staging
OUTPUT_DIR=$STAGING_DIR/output

TORSH_PKG_VERSION_LINE=$(grep "^PKG_VERSION" torsh-openwrt-pkg/Makefile)
TORSH_VERSION=${TORSH_PKG_VERSION_LINE#*=}

echo "Creating tar for $TARGET_OPENWRT_ARCH based on $TARGET_RUSTC_ARCH"
mkdir -p $OUTPUT_DIR/torsh-$TORSH_VERSION/
cp -r $STAGING_DIR/dummy-openwrt-src/* $OUTPUT_DIR/torsh-$TORSH_VERSION/
cp $STAGING_DIR/build/$TARGET_RUSTC_ARCH/*/torsh-node $OUTPUT_DIR/torsh-$TORSH_VERSION/ # where * is either `debug` or `release`
tar -czvf "$OUTPUT_DIR/torsh-node_${TARGET_OPENWRT_ARCH}_$TORSH_VERSION-1.tar.gz" -C $OUTPUT_DIR/ torsh-$TORSH_VERSION/
rm -rf $OUTPUT_DIR/torsh-$TORSH_VERSION/