ARG BASE_IMAGE_TAG=3.20.2
ARG GOSTATSD_TAG=36.0.2

FROM atlassianlabs/gostatsd:$GOSTATSD_TAG as gostatsd

FROM alpine:$BASE_IMAGE_TAG

RUN apk --no-cache add \
    ca-certificates file

RUN apk update && apk upgrade

COPY --from=gostatsd /bin/gostatsd /bin/gostatsd

COPY ./nri-statsd.sh .
COPY ./run-statsd.sh .

ENTRYPOINT ["/nri-statsd.sh"]
