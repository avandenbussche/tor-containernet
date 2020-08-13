FROM alpine:edge

RUN apk add --no-cache curl tor bash iproute2

COPY scripts/entrypoint.sh /usr/local/bin/

CMD ["entrypoint.sh"]
