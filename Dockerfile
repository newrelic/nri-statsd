FROM atlassianlabs/gostatsd:40.0.1 AS gostatsd

FROM alpine:3.21.3

RUN apk --no-cache add \
    ca-certificates file netcat-openbsd procps grep coreutils bash curl

RUN apk update && apk upgrade

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .
COPY ./test-root-endpoint.sh .
COPY ./test-health-check.sh .

ENTRYPOINT ["/nri-statsd.sh"]
