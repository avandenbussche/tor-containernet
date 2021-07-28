FROM alpine:3.13.0

RUN apk add --no-cache \
	curl \
	bash \
	iproute2 \
	build-base \
	automake \
	autoconf \
	libevent-dev \
	openssl-dev \
	zlib-dev \
	cmake \
        cargo

ADD tor tor

WORKDIR /tor/src/lib/quiche
RUN cargo build --release
RUN cp target/release/libquiche.so /usr/local/lib/

WORKDIR /tor
RUN ./autogen.sh
RUN ./configure --disable-asciidoc
RUN make -j20
RUN make install

COPY scripts/entrypoint.sh /usr/local/bin/

WORKDIR /usr/local/etc/tor

CMD ["entrypoint.sh"]
