# torsh-build

*Developed as part of COSC 99 Thesis Research as part of the SPLICE Project at Dartmouth College during winter and spring 2022.*




## Overview

This repository contains utilities to build and test [TorSH](https://github.com/avandenbussche/torsh). More specifically, use this repository to:

* develop and compile TorSH for both local or foreign architectures
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
* `make torsh-cross RUSTC_ARCH=<rustc-arch>`
  * Requires the `cross` Rust utility (install with `cargo install cross`)
  * Compiles the local TorSH submodule for the target architecture using `cross build`
  * To see a list of available target architectures, run `make util-print-targets`
* `make torsh-cross-clean`
  * Cleans all cross-compiled versions of TorSH (made using `make torsh-cross` from the staging directory (does not delete `debug` versions compiled for the host)

All built artifacts are moved into the `staging/` directory at the root of the repository.

#### Sample Workflow

For local development, simply compile TorSH using `make torsh`. When compiling for architechtures other than that of the test machine, the use of `make torsh-cross RUSTC_ARCH=<rustc-arch>` is required. Note that OpenWrt uses the `musl` instead of the `gnu` library.



### Launching a Containernet Swarm

The `Makefile` offers the following targets to test TorSH locally in Containernet swarm:

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

#### Sample Workflow

To launch a local TorSH Containernet swarm, first ensure a base Docker image is cached by running `make containernet-base`.

If TorSH is to be recompiled, run

1. `make torsh`
2. `make containernet-image`

To launch a fresh swarm, run

1. `make containernet-quic` or `make containernet-vanilla`
2. `make containernet-run`

If Containernet crashes, run

1. `make containernet-cleanup`



### Compiling the OpenWrt TorSH Package

The `Makefile` offers the following targets to compile and test the TorSH OpenWrt package locally:

* `make openwrt-build-ipk OPENWRT_ARCH=<openwrt-arch> OPENWRT_SDK=<openwrt-sdk-image>`
  * Builds and packages the version of the `torsh-openwrt-pkg` submodule located in the root of the repository
  * Note that the binaries must be pre-compiled as OpenWrt devices cannot currently compile Rust locally
* `make openwrt-build-package-index`
  * Builds the `Packages.gz` and `Packages.sig` required for an OpenWrt package repository, including all locally built `.ipk`s, using the host's architecture for the Docker container. 
* `make openwrt-launch-test-image`
  * Launches a Docker container containing an OpenWrt rootfs
  * Commands to install and test the package must be entered manually for now (see below)
* `make openwrt-launch-dummy-server`
  * Launches a local instance of `torsh-server` serving the binary tarballs for the OpenWrt compilation container
* `make openwrt-clean`
  * Cleans contents of `staging/output/`, where all built OpenWrt artifacts are stored

#### Sample Workflow

To rebuild the `.ipk` from a fresh TorSH compilation for the target architecture, run:

1. `make torsh-cross RUSTC_ARCH=<rustc-arch>`
2. `make util-generate-tar OPENWRT_ARCH=<openwrt-arch> RUSTC_ARCH=<rustc-arch>`
3. `make openwrt-build-ipk OPENWRT_ARCH=<openwrt-arch> OPENWRT_SDK=<openwrt-sdk-image>`

For example, for a 64-bit ARM processor:

1. `make torsh-cross RUSTC_ARCH=aarch64-unknown-linux-musl`
2. `make util-generate-tar OPENWRT_ARCH=aarch64-openwrt-linux-musl RUSTC_ARCH=aarch64-unknown-linux-musl`
3. `make openwrt-build-ipk OPENWRT_ARCH=aarch64-openwrt-linux-musl OPENWRT_SDK=aarch64_cortex-a72-21.02.2`

To test the built package on the local machine (the following example assumes an `x86_64` architecture), first launch a dummy server by running `make openwrt-launch-dummy-server` on the host machine. Then build the package for the target machine and launch a test image by running:

1. `make torsh-cross RUSTC_ARCH=x86_64-unknown-linux-musl`
2. `make util-generate-tar OPENWRT_ARCH=x86_64-openwrt-linux-musl RUSTC_ARCH=x86_64-unknown-linux-musl`
3. `make openwrt-build-ipk OPENWRT_ARCH=x86_64-openwrt-linux-musl OPENWRT_SDK=x86_64-21.02.1`
4. `make openwrt-build-package-index`
5. `make openwrt-launch-test-image`

##### Checking Logs

Check Tor and TorSH logs by running `logread` from any OpenWrt instance, virtual or physical.


## Utilities

The `Makefile` offers the following utilities to help with various build and test needs:

* `make util-generate-tar OPENWRT_ARCH=<openwrt-arch> RUSTC_ARCH=<rustc-arch>`
  * Generates a source tarball to be fed to the OpenWrt SDK container by the dummy server
* `make util-print-targets`
  * Prints possible options for Rust cross-compilation targets (`<rustc-arch>`)



## Architecture Equivalents

Annoyingly, `rustc` and OpenWrt use slightly different names for different architectures (although there appears to be a pattern, sometimes it does not hold). Use the following table for equivalencies while building the OpenWrt packages, substituting different OpenWrt version numbers as desired. The OpenWrt image tags are available from [Docker Hub](https://hub.docker.com/r/openwrtorg/sdk/tags). Many images might be possible for a given architecture.

| Rust Arch. (`<rustc-arch>`)       | OpenWrt Arch. (`<openwrt-arch>`) | SDK Image (`<openwrt-sdk-image>`) | Notes                             |
| --------------------------------- | -------------------------------- | --------------------------------- | --------------------------------- |
| `arm-unknown-linux-musleabihf`    | `arm-openwrt-linux-muslgnueabi`  | `arm_arm1176jzf-s_vfp-21.02.2`    | Raspberry Pi Model B+             |
| `arm-unknown-linux-musleabihf`    | `arm-openwrt-linux-muslgnueabi`  | `arm_cortex-a7_neon-vfpv4-21.02.2`| Raspberry Pi 2 Model B v1.0/1.1   |
| `aarch64-unknown-linux-musl`      | `aarch64-openwrt-linux-musl`     | `aarch64_cortex-a72-21.02.2`      | Raspberry Pi 4 (64-bit)           |
| `mipsel-unknown-linux-musl`       | `mipsel-openwrt-linux-musl`      | `mipsel_mips32-21.02.1`           | Possibly a popular OpenWrt arch.? |
| `x86_64-unknown-linux-musl`       | `x86_64-openwrt-linux-musl`      | `x86_64-21.02.1`                  | 64-bit Linux test env             |



## Known Issues

### OpenSSL Cross-Compilation

The `cross` utility uses a slightly out-of-date version of `libc`, sometimes resulting in such an error:

```
error: failed to run custom build command for `openssl-sys v0.9.72`

Caused by:
  process didn't exit successfully: `/target/debug/build/openssl-sys-6a1c3c766acecfc0/build-script-main` (exit status: 1)
  --- stderr
  /target/debug/build/openssl-sys-6a1c3c766acecfc0/build-script-main: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.25' not found (required by /target/debug/build/openssl-sys-6a1c3c766acecfc0/build-script-main)
  /target/debug/build/openssl-sys-6a1c3c766acecfc0/build-script-main: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.27' not found (required by /target/debug/build/openssl-sys-6a1c3c766acecfc0/build-script-main)
warning: build failed, waiting for other jobs to finish...
error: build failed
make: *** [Makefile:24: torsh-cross] Error 101
```

This seems to only be an issue for GNU architectures, such as `armv7-unknown-linux-gnueabihf` (contains optimizations for newer Raspberry Pis) or `x86_64-linux-gnu`. While workarounds are possible, they result in tinkering with the `cross` build scripts and Dockerfiles, which is something beyond the scope of this project. For the time being, TorSH unfortunately will not be supported on architectures facing this issue.

### Infinite UDP over TCP Redirect Loops in Containernet

Because of the inability to differentiate between PREROUTING and OUTPUT packets in Containernet, sending UDP traffic over TCP in a local Containernet environment will result in UDP over TCP packets being indefinitely bounced around the swarm. This could probably be fixed by having the TorSH process owned by its own user, but this seemed at first glance to have stranger interactions with the `iptables` utility... fixing this is not a priority right now given the tight thesis deadlines!
