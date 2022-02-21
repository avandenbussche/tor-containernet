#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

OPENWRT_VERSION="21.02.1"

ARCH="${RUST_TARGET_ARCH/"unknown"/"openwrt"}"		# e.g. x86_64-openwrt-linux-musl
ARCH_FAMILY="${ARCH%%-*}"                         	# e.g. x86_64
ARCH_IMAGE_TAG="$ARCH_FAMILY-$OPENWRT_VERSION"     	# e.g. x86_64-21.02.1      

echo "Working in directory $ROOT_DIR"
echo "Building openwrt ipk for $ARCH ($ARCH_FAMILY) with image tag $ARCH_IMAGE_TAG"

docker run --rm -v $STAGING_DIR/openwrt/bin/:/home/build/openwrt/bin/ \
				-v $ROOT_DIR/torsh-openwrt-pkg/:/home/build/openwrt/package/torsh/ \
				--network="host" -it openwrtorg/sdk:$ARCH_IMAGE_TAG /bin/bash -c "\
														./scripts/feeds update base && \
														make defconfig && \
														./scripts/feeds install torsh && \
														sudo make package/torsh/compile -j1 V=s"
cp $STAGING_DIR/openwrt/bin/packages/$ARCH_FAMILY/base/torsh_0.1-1_$ARCH_FAMILY.ipk "$OUTPUT_DIR/torsh-node_${ARCH}_0.1-1.ipk"