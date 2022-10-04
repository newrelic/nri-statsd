#!/bin/sh

if [ ! -z "${NR_STATSD_VERBOSE}" ]; then
    EXTRA_ARGS="--verbose"
fi

exec /bin/gostatsd --hostname "${HOSTNAME}" --default-tags "hostname:${HOSTNAME} ${TAGS}" --config-path "${NR_STATSD_CFG}" "${EXTRA_ARGS}"
