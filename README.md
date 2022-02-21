# torsh-build

*Developed as part of COSC 99 Thesis Research as part of the SPLICE Project at Dartmouth College during winter and spring 2022.*




## Overview

This repository contains utilities to build and test [TorSH](https://github.com/avandenbussche/torsh). Use this repository to:

* develop and compile TorSH
* test TorSH in a local Containernet swarm
* build and test the TorSH OpenWrt package locally




## Build Commands and Sample Workflows

All `make` commands are to be executed from the root or the repository.

### Compiling TorSH

The `Makefile` offers the following targets to compile TorSH:

* `make torsh`
  * Compiles the local TorSH submodule for the host's architecture using `cargo build`
* `make torsh-clean`
  * Cleans the local TorSH submodule compiled for the host using `cargo clean`
* `make torsh-cross TARGET_ARCH=<rustc-arch-triple>`
  * Requires the `cross` Rust utility (install with `cargo install cross`)
  * Compiles the local TorSH submodule for the target architecture using `cross build`
  * To see a list of available target architectures, run `make util-print-targets`

All built artifacts are moved into the `staging/` directory at the root of the repository.



### Launching a Containernet Swarm

The `Makefile` offers the following targets to test TorSH locally in Containernet swam:

* `make containernet-base`
  * Builds the base Docker image for the Containernet nodes (only contains dependencies; doing this helps reduce build times during development)
* `make containernet-image`
  * Builds the Docker image for the Containernet nodes containing the last compiled version of TorSH
* `make containernet-quic` and `make containernet-vanilla`
  * Generates configurations for either a QUIC-based or vanilla Tor network
* `make containernet-run`
  * Launches the Containernet swarm for testing
* `make containernet-cleanup`
  * Cleans up lingering Docker containers in the event that Containernet crashes



### Compiling the OpenWrt TorSH Package

The `Makefile` offers the following targets to compile and test the TorSH OpenWrt package locally:

* `make openwrt-build-ipk`
  * Builds and packages the version of the `torsh-openwrt-pkg` submodule located in the root of the repository
  * Note that the binaries must be pre-compiled as OpenWrt devices cannot currently compile Rust locally
* `make openwrt-launch-test-image`
  * Launches a Docker container containing an OpenWrt rootfs
  * Commands to install and test the package must be entered manually for now (see below)
* `make openwrt-launch-dummy-server`
  * Launches a local instance of `torsh-server` serving the binary tarballs for the OpenWrt compilation container