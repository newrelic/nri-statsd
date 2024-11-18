FROM atlassianlabs/gostatsd:36.0.2 AS gostatsd

FROM alpine:3.20.3

RUN apk --no-cache add \
    ca-certificates file

RUN apk update && apk upgrade

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
