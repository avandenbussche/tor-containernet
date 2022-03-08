#!/bin/bash

STAGING_DIR=staging
OUTPUT_DIR=$STAGING_DIR/output

echo "Creating tar for $TARGET_OPENWRT_ARCH based on $TARGET_RUSTC_ARCH"
mkdir -p $OUTPUT_DIR/torsh-0.1/
cp -r $STAGING_DIR/dummy-openwrt-src/* $OUTPUT_DIR/torsh-0.1/
cp $STAGING_DIR/build/$TARGET_RUSTC_ARCH/*/torsh-node $OUTPUT_DIR/torsh-0.1/ # where * is either `debug` or `release`
tar -czvf "$OUTPUT_DIR/torsh-node_${TARGET_OPENWRT_ARCH}_0.1-1.tar.gz" -C $OUTPUT_DIR/ torsh-0.1/
rm -rf $OUTPUT_DIR/torsh-0.1/