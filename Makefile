# Leave info first so it's the default!
info:
	@echo "Welcome to torsh-build. Please specify a make command."

# Prevents false "target up to date" messages
.PHONY: torsh

# Get absolute path to this directory
PWD:=$(shell pwd)


HOST_ARCH:=$(shell rustc -vV | awk '/^host/ { print $$2 }')
ifndef TARGET_ARCH
	TARGET_ARCH:=$(HOST_ARCH)
endif

torsh:
	cargo build --manifest-path torsh/Cargo.toml --target-dir staging/build/ 

torsh-clean:
	cargo clean --manifest-path torsh/Cargo.toml --target-dir staging/build/

torsh-cross:
	cd torsh/ && cross build --target $(TARGET_ARCH)
	mv torsh/target/$(TARGET_ARCH) staging/build/$(TARGET_ARCH)


containernet-base:
	docker build -t torsh-base -f torsh-base/Dockerfile .

containernet-image: util-generate-tars
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
	docker rm -f $(sudo docker ps --filter 'name=mn.' -a -q) 2> /dev/null || echo "No containers to clean up"
	mn -c



openwrt-build-ipk:
	RUST_TARGET_ARCH=$(TARGET_ARCH) ./scripts/build_ipk.sh

openwrt-launch-test-image:
	RUST_TARGET_ARCH=$(TARGET_ARCH) ./scripts/launch_openwrt_test_image.sh

openwrt-launch-dummy-server:
	./staging/build/$(HOST_ARCH)/debug/torsh-server --authlist-file torsh/tests/sample_authlist_db.json \
													--whitelist-file torsh/tests/sample_whitelist_db.json \
													--release-bin-dir staging/output/

util-generate-tars:
	./scripts/generate_bin_tars.sh

util-print-targets:
	rustc --print target-list