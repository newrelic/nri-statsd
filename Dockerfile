ARG GOSTATSD_TAG=20.3.2

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG

COPY ./nri-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
