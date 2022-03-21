#!/bin/bash

ROOT_DIR=$(pwd)
STAGING_DIR=$ROOT_DIR/staging
OUTPUT_DIR=$STAGING_DIR/output

echo "Working in directory $ROOT_DIR"
echo "Making OpenWrt package index"

docker run --rm -v $STAGING_DIR/openwrt/bin/:/home/build/openwrt/bin/ \
				-v $ROOT_DIR/torsh-openwrt-pkg/:/home/build/openwrt/package/torsh/ \
				-v $ROOT_DIR/keys/:/home/build/openwrt/keys/ \
				--network="host" -it openwrtorg/sdk:$TARGET_OPENWRT_SDK /bin/bash -c "\
						./scripts/feeds update base && \
						make defconfig && \
						./scripts/feeds install base-files && \
						export PATH=$PATH:~/openwrt/staging_dir/host/bin && \
						sudo /bin/bash -c 'export PATH=$PATH:/home/build/openwrt/staging_dir/host/bin && \
                            ./scripts/ipkg-make-index.sh ./bin/packages/ > ./bin/packages/Packages' && \
						sudo gzip -fk ./bin/packages/Packages && \
						sudo ./staging_dir/host/bin/usign -S -m ./bin/packages/Packages -s ./keys/secret.key -x ./bin/packages/Packages.sig"

TARGET_DIR=$OUTPUT_DIR/openwrt/bin/packages/
mkdir -p $TARGET_DIR
cp -r $STAGING_DIR/openwrt/bin/packages/. $TARGET_DIR
mv $TARGET_DIR/Packages* $OUTPUT_DIR/openwrt/