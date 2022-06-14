ARG GOSTATSD_TAG=35.0.0

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
