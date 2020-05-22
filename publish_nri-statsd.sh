#!/bin/bash

[ -z "$1" ] && echo "please specify a version for the container image" && exit 1

docker build -t newrelic/nri-statsd .
docker tag newrelic/nri-statsd newrelic/nri-statsd:$1
docker login
docker push newrelic/nri-statsd:latest
docker push newrelic/nri-statsd:$1
