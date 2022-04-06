ARG GOSTATSD_TAG=34.2.1

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG

COPY ./nri-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
