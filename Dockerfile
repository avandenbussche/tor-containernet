# syntax=docker/dockerfile:experimental
FROM torsh-base:latest

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y python3-pip
RUN apt-get install -y iproute2
RUN apt-get install -y pkg-config
RUN apt-get install -y net-tools

ADD bwtool/bwtool.py /torsh/bwtool/
ADD bwtool/requirements.txt /torsh/bwtool/
WORKDIR /torsh/bwtool
RUN pip3 install -r requirements.txt
RUN cp bwtool.py /usr/local/bin/

COPY scripts/entrypoint.sh /usr/local/bin/

ADD torsh /torsh/torsh-bin/.
WORKDIR /torsh/torsh-bin
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/torsh/torsh-bin/target \
    cargo build

WORKDIR /usr/local/etc/tor

CMD ["entrypoint.sh"]
