# syntax=docker/dockerfile:1
FROM ubuntu:20.04

# enter working directory
WORKDIR /torsh

# install cmake and tor dependencies
RUN apt-get update
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y curl
RUN apt-get install -y build-essential
RUN apt-get install -y git
RUN apt-get install -y libssl-dev
RUN apt-get install -y autotools-dev
RUN apt-get install -y automake
RUN apt-get install -y libevent-dev
RUN apt-get install -y zlib1g
RUN apt-get install -y zlib1g-dev

# install latest cmake
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz | tar -zxv
WORKDIR /torsh/cmake-3.22.1
RUN ./bootstrap
RUN make
RUN make install

# enter working directory
WORKDIR /torsh

# install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile=minimal -y
ENV PATH="/root/.cargo/bin:${PATH}"
# RUN rustup default nightly

# enter working directory
WORKDIR /torsh

# clone Tor over QUIC repository
RUN git clone --recursive https://github.com/avandenbussche/tor.git
# install Quiche
WORKDIR /torsh/tor/src/lib/quiche
RUN cargo build --release --features ffi
RUN cp target/release/libquiche.so /usr/local/lib/
RUN ldconfig

# build Tor
WORKDIR /torsh/tor
RUN sh autogen.sh
RUN ./configure --disable-asciidoc
RUN make
RUN make install

# install other dependencies 
RUN apt-get install -y python3-pip
RUN apt-get install -y iproute2
RUN apt-get install -y pkg-config
RUN apt-get install -y net-tools
RUN apt-get install -y ipset
RUN apt-get install -y dnsutils
RUN apt-get install -y sudo
RUN apt-get install -y libnfnetlink-dev
RUN apt-get install -y libmnl-dev
RUN apt-get install -y netcat

WORKDIR /torsh
RUN curl -L https://www.netfilter.org/pub/libnetfilter_queue/libnetfilter_queue-1.0.5.tar.bz2 | tar -xvj
WORKDIR /torsh/libnetfilter_queue-1.0.5
RUN ./configure
RUN make
RUN make install