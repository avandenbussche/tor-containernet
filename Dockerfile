FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        build-essential \
        automake \
        cmake \
        libssl-dev \
        libevent-dev \
        libz-dev \
        python3 \
        python3-pip \
        iputils-ping \
        net-tools \
        iproute2 \
        bash \
        && rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh && chmod +x rustup.sh && ./rustup.sh -y  && ~/.cargo/bin/rustup install 1.54

ADD tor tor

WORKDIR /tor/src/lib/quiche
RUN ~/.cargo/bin/cargo build --release --features ffi
RUN cp target/release/libquiche.so /usr/local/lib/
RUN ldconfig

WORKDIR /tor
RUN ./autogen.sh
RUN ./configure --disable-asciidoc
RUN make -j20
RUN make install

ADD bwtool/bwtool.py /bwtool/
ADD bwtool/requirements.txt /bwtool/
WORKDIR /bwtool
RUN pip3 install -r requirements.txt
RUN cp bwtool.py /usr/local/bin/

COPY scripts/entrypoint.sh /usr/local/bin/

WORKDIR /usr/local/etc/tor

CMD ["entrypoint.sh"]
