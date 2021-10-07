#!/usr/bin/env bash

STATSD_CONTAINER="statsd"
NRI_STATSD_IMAGE="nri-statsd"
NRI_STATSD_CONTAINER="newrelic-statsd"

# install docker if not installed
which docker || curl -fsSL https://get.docker.com | sh

# build and nri-statds
cd /srv
docker rm -f $NRI_STATSD_CONTAINER
docker build -t $NRI_STATSD_IMAGE  .
docker run -d -it --rm \
  --name $NRI_STATSD_CONTAINER \
  -h $(hostname) \
  -e NR_ACCOUNT_ID="$NR_ACCOUNT_ID" \
  -e NR_API_KEY="$NR_API_KEY" \
  -e NR_EU_REGION="$NR_EU_REGION" \
  -p 8125:8125/udp \
  nri-statsd