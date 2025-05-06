FROM atlassianlabs/gostatsd:40.0.1 AS gostatsd

FROM alpine:3.21.3

RUN apk --no-cache add \
    ca-certificates file netcat-openbsd

RUN apk update && apk upgrade

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .
COPY ./health-server.sh .

ENTRYPOINT ["/nri-statsd.sh"]
