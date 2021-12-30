ARG GOSTATSD_TAG=33.0.2

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG

COPY ./nri-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
