#!/bin/sh

if [ ! -z "${NR_STATSD_VERBOSE}" ]; then
    EXTRA_ARGS="--verbose"
fi

# Make health-server.sh executable
chmod +x ./health-server.sh

# Start the health check server in the background
./health-server.sh ${NR_MONITORING_PORT} &
HEALTH_SERVER_PID=$!

# Start gostatsd
exec /bin/gostatsd --hostname "${HOSTNAME}" --default-tags "hostname:${HOSTNAME} ${TAGS}" --config-path "${NR_STATSD_CFG}" "${EXTRA_ARGS}"
