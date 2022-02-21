# syntax=docker/dockerfile:1
FROM torsh-base:latest
# TODO: copy torsh-base contents into here instead 

COPY torsh-containernet/bwtool/bwtool.py /torsh/bwtool/
COPY torsh-containernet/bwtool/requirements.txt /torsh/bwtool/
WORKDIR /torsh/bwtool
RUN pip3 install -r requirements.txt
RUN cp bwtool.py /usr/local/bin/
COPY torsh-containernet/scripts/entrypoint.sh /usr/local/bin/

RUN mkdir /torsh/authlist
RUN mkdir /torsh/whitelist
COPY torsh/tests/sample_authlist_db.json /torsh/authlist/torsh_nodelist-0.json
COPY torsh/tests/sample_whitelist_db.json /torsh/whitelist/torsh_whitelist-0.json
COPY staging/tars/* /torsh/node-releases/
WORKDIR /torsh/bin
COPY staging/build/x86_64-unknown-linux-gnu/debug/torsh-node .
COPY staging/build/x86_64-unknown-linux-gnu/debug/torsh-server .

WORKDIR /usr/local/etc/tor
CMD ["entrypoint.sh"]