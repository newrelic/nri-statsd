FROM atlassianlabs/gostatsd:39.1.13 as gostatsd

FROM alpine:3.20.2

RUN apk --no-cache add \
    ca-certificates file

RUN apk update && apk upgrade

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
