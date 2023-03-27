ARG BASE_IMAGE_TAG=3.17.2
ARG GOSTATSD_TAG=35.1.19

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG as gostatsd

FROM alpine:$BASE_IMAGE_TAG

RUN apk -U upgrade

RUN apk --no-cache add \
    ca-certificates file

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
