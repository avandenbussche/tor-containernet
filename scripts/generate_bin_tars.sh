#!/bin/bash

STAGING_DIR=staging
OUTPUT_DIR=$STAGING_DIR/output

for dir in staging/build/*/ ; do
    ARCH=$(basename $dir)
    if [ "$ARCH" = "debug" ]; then
        continue
    fi
    OPENWRT_ARCH="${ARCH/"unknown"/"openwrt"}"
    echo "Creating tar for $OPENWRT_ARCH"
    mkdir -p $OUTPUT_DIR/torsh-0.1/
    cp -r $STAGING_DIR/dummy-openwrt-src/* $OUTPUT_DIR/torsh-0.1/
    cp $dir/debug/torsh-node $OUTPUT_DIR/torsh-0.1/
    tar -czvf "$OUTPUT_DIR/torsh-node_${OPENWRT_ARCH}_0.1-1.tar.gz" -C $OUTPUT_DIR/ torsh-0.1/
    rm -rf $OUTPUT_DIR/torsh-0.1/
done