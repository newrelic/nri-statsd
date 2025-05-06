#!/bin/sh

if [ ! -z "${NR_STATSD_VERBOSE}" ]; then
    EXTRA_ARGS="--verbose"
fi

# Create log directory
mkdir -p /var/log/gostatsd

# Create a named pipe for logging
FIFO_PATH="/var/log/gostatsd/gostatsd.pipe"
rm -f $FIFO_PATH
mkfifo $FIFO_PATH

# Start a background process to read from the pipe and write to a log file
cat $FIFO_PATH > /var/log/gostatsd/gostatsd.log &
LOG_PID=$!

# Make health-check.sh executable
chmod +x ./health-check.sh

# Start the health check server in the background
# This will handle health checks on port ${NR_MONITORING_PORT} or a different port if that one is in use
./health-check.sh ${NR_MONITORING_PORT} &
HEALTH_CHECK_PID=$!

# Start gostatsd with exec, but redirect output to our pipe
# The exec command replaces the current shell with gostatsd, which is important for container environments
exec /bin/gostatsd --hostname "${HOSTNAME}" --default-tags "hostname:${HOSTNAME} ${TAGS}" --config-path "${NR_STATSD_CFG}" "${EXTRA_ARGS}" 2>&1 > $FIFO_PATH
