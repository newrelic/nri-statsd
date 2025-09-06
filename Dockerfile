FROM atlassianlabs/gostatsd:40.0.1 AS gostatsd

FROM alpine:3.21.3

RUN apk update && apk upgrade && \
    apk --no-cache add \
    ca-certificates file

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

# Expose ports for StatsD UDP and HTTP Health Checks
EXPOSE 8125/udp 8080

ENTRYPOINT ["/nri-statsd.sh"]
