#!/bin/sh

exec /bin/gostatsd --hostname ${HOSTNAME} --default-tags "hostname:${HOSTNAME} ${TAGS}" --config-path $NR_STATSD_CFG