#!/bin/sh

NR_INSIGHTS_COLLECTOR="insights-collector"
NR_INSIGHTS_DOMAIN="newrelic.com"
NR_METRICS_COLLECTOR="metric-api"
NR_METRICS_DOMAIN="newrelic.com"

if [ ! -z "${NR_EU_REGION}" ]; then
    NR_INSIGHTS_DOMAIN="eu01.nr-data.net"
    NR_METRICS_DOMAIN="eu."$NR_METRICS_DOMAIN
fi

if [ ! -z "${NR_GOV_COLLECTOR}" ]; then
    NR_INSIGHTS_COLLECTOR="gov-insights-collector"
    NR_METRICS_COLLECTOR="gov-infra-api"
fi

GO_STATSD_BIN=/bin/gostatsd

if [ ! -z "${HOSTNAME}" ]; then
    GO_STATSD_BIN="/bin/gostatsd --hostname ${HOSTNAME}"
fi

if [ -z "${NR_STATSD_METRICS_ADDR}" ]; then
    NR_STATSD_METRICS_ADDR=":8125"
fi

# per FHS, host local software packages should be in /usr/local and their config files in /usr/local/etc
# could be argued that gostatsd is an optional package and therefore be in /opt/{package} and config files in /etc/opt/{package}..
# nevertheless, gostatsd binary is in /bin, but let's assume we are following fhs best pratices
NR_STATSD_CFG=/etc/opt/newrelic/nri-statsd.toml

if [ ! -f "${NR_STATSD_CFG}" ]; then
  /bin/cat <<EOF
WARNING: configuration file not found, generating one based on default values.
make sure you have provided the required NR_API_KEY and optionally
NR_ACCOUNT_ID if using Insights events, via environment variables.
EOF

  NR_STATSD_CFG=/tmp/nri-statsd.toml
  /bin/cat <<EOM >${NR_STATSD_CFG}

backends='newrelic'
metrics-addr="${NR_STATSD_METRICS_ADDR}"

[newrelic]
flush-type = "metrics"
transport = "default"
address = "https://${NR_INSIGHTS_COLLECTOR}.${NR_INSIGHTS_DOMAIN}/v1/accounts/${NR_ACCOUNT_ID}/events"
address-metrics = "https://${NR_METRICS_COLLECTOR}.${NR_METRICS_DOMAIN}/metric/v1"
api-key = "${NR_API_KEY}"
EOM
fi

GO_STATSD_CFG="--config-path ${NR_STATSD_CFG}"

GO_STATSD_TAGS="--default-tags \"hostname:${HOSTNAME} ${TAGS}\""

CMD="${GO_STATSD_BIN} ${GO_STATSD_CFG} ${GO_STATSD_TAGS}"

echo "---- Starting gostatsd: ${CMD} ----"

eval "$CMD"
