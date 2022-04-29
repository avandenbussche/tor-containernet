# Leave info first so it's the default!
info:
	@echo "Welcome to torsh-build. Please specify a make command."

# Prevents false "target up to date" messages
.PHONY: torsh

# Get absolute path to this directory
PWD:=$(shell pwd)

# Define defaults
HOST_RUSTC_ARCH:=$(shell rustc -vV | awk '/^host/ { print $$2 }')
ifndef RUSTC_ARCH
	RUSTC_ARCH:=$(HOST_RUSTC_ARCH)
endif

HOST_OPENWRT_ARCH:=$(shell ${HOST_RUSTC_ARCH/"unknown"/"openwrt"})
ifndef OPENWRT_ARCH
	OPENWRT_ARCH:=$(HOST_OPENWRT_ARCH)
endif

ifndef OPENWRT_SDK
	OPENWRT_SDK:="x86_64-21.02.1"
endif



torsh:
	cargo +nightly build --manifest-path torsh/Cargo.toml --target-dir staging/build/ --features server

torsh-clean:
	cargo clean --manifest-path torsh/Cargo.toml --target-dir staging/build/

torsh-cross:
	cd torsh/ && cross +nightly build --target $(RUSTC_ARCH) --release --lib --bin torsh-node
	rm -rf staging/build/$(RUSTC_ARCH)
	cp -r torsh/target/$(RUSTC_ARCH) staging/build/$(RUSTC_ARCH)

torsh-cross-clean:
	find ./staging/build -mindepth 1 ! -regex '^./staging/build/debug\(/.*\)?' -delete


containernet-base:
	docker build -t torsh-base -f torsh-base/Dockerfile .

containernet-image:
	touch staging/output/notempty # Prevents error that output dir is empty during Docker build
	docker build -t torsh-containernet -f torsh-containernet/Dockerfile . --no-cache

containernet-quic:
	rm -rf torsh-continernet/nodes/
	cd torsh-containernet/ && ./create_network.sh quic

containernet-vanilla:
	cd torsh-containernet/ && ./create_network.sh vanilla

containernet-run:
	sudo service openvswitch-switch start
	cd torsh-containernet/ && sudo ./tor_runner.py -i torsh-containernet

containernet-cleanup:
	sudo docker rm -f $(docker ps --filter 'name=mn.' -a -q) 2> /dev/null || echo "No containers to clean up"
	sudo mn -c




openwrt-build-ipk:
	TARGET_OPENWRT_SDK=$(OPENWRT_SDK) TARGET_OPENWRT_ARCH=$(OPENWRT_ARCH) ./scripts/build_ipk.sh

openwrt-build-package-index:
	TARGET_OPENWRT_SDK=$(OPENWRT_SDK) ./scripts/build_package_index.sh

openwrt-launch-test-image:
	TARGET_OPENWRT_SDK=$(OPENWRT_SDK) TARGET_OPENWRT_ARCH=$(OPENWRT_ARCH) ./scripts/launch_openwrt_test_image.sh

openwrt-launch-dummy-server: torsh
	ROCKET_ADDRESS="0.0.0.0" ROCKET_PORT=80 ROCKET_LIMITS={string="512 MiB"} ./staging/build/debug/torsh-server \
					--whitelist-file torsh/tests/sample_whitelist_db.json \
					--release-bin-dir staging/output/

openwrt-clean:
	sudo rm -rf staging/openwrt/*
	rm -rf staging/output/*

util-generate-tar:
	TARGET_RUSTC_ARCH=$(RUSTC_ARCH) TARGET_OPENWRT_ARCH=$(OPENWRT_ARCH) ./scripts/generate_bin_tar.sh

util-print-targets:
	rustc --print target-list
