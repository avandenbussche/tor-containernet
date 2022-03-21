#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

echo "Launching openwrt test image"

# Per https://github.com/openwrt/docker/issueNs/76#issuecomment-877423899,
#  need --entrypoint flag with --cap-add or else networking breaks
docker run --rm -v $ROOT_DIR/scripts/openwrt_scripts:/usr/bin/torsh-scripts/ \
                -v $ROOT_DIR/keys/:/keys/ \
                --env TORSH_IN_DOCKER=1 \
                --cap-add=NET_ADMIN \
                --cap-add=NET_RAW \
                --entrypoint /usr/bin/torsh-scripts/openwrt_test_image_init.sh \
                -it openwrtorg/rootfs:$TARGET_OPENWRT_SDK