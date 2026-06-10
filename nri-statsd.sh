#!/bin/sh

set -eo pipefail

# Use environment variables to override the endpoints sub domains
NR_INSIGHTS_COLLECTOR="${NR_INSIGHTS_COLLECTOR:-insights-collector}"
NR_INSIGHTS_DOMAIN="newrelic.com"
NR_METRICS_COLLECTOR="${NR_METRICS_COLLECTOR:-metric-api}"
NR_METRICS_DOMAIN="newrelic.com"

get_region_from_api_key() {
    if [ -z "${1}" ]; then
        return
    fi

    # Region-aware keys use 'x'. Strip from first x/X onward, then trim numeric sub-region suffix.
    API_KEY_PREFIX=$(printf '%s' "${1}" | sed 's/[xX].*$//')
    REGION_FROM_KEY=$(printf '%s' "${API_KEY_PREFIX}" | sed 's/[0-9]*$//' | tr '[:upper:]' '[:lower:]')

    if [ -n "${REGION_FROM_KEY}" ]; then
        printf '%s' "${REGION_FROM_KEY}"
    fi
}

NR_REGION=$(get_region_from_api_key "${NR_API_KEY}")

if [ -n "${NR_REGION}" ]; then
    case "${NR_REGION}" in
        eu)
            NR_INSIGHTS_DOMAIN="eu01.nr-data.net"
            NR_METRICS_DOMAIN="eu."$NR_METRICS_DOMAIN
            ;;
        *)
            NR_INSIGHTS_DOMAIN="${NR_REGION}.nr-data.net"
            NR_METRICS_DOMAIN="${NR_REGION}.nr-data.net"
            ;;
    esac
fi

# Backward compatibility: explicit NR_EU_REGION still overrides auto-selection.
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

if [ -z "${NR_ENDPOINT_ADDR}" ]; then
    NR_ENDPOINT_ADDR="https://${NR_INSIGHTS_COLLECTOR}.${NR_INSIGHTS_DOMAIN}/v1/accounts/${NR_ACCOUNT_ID}/events"
fi

if [ -z "${NR_ENDPOINT_METRICS_ADDR}" ]; then
    NR_ENDPOINT_METRICS_ADDR="https://${NR_METRICS_COLLECTOR}.${NR_METRICS_DOMAIN}/metric/v1"
fi

# per FHS, host local software packages should be in /usr/local and their config files in /usr/local/etc
# could be argued that gostatsd is an optional package and therefore be in /opt/{package} and config files in /etc/opt/{package}..
# nevertheless, gostatsd binary is in /bin, but let's assume we are following fhs best pratices
export NR_STATSD_CFG=/etc/opt/newrelic/nri-statsd.toml

if [ ! -f "${NR_STATSD_CFG}" ]; then
  /bin/cat <<EOF
WARNING: configuration file not found, generating one based on default values.
make sure you have provided the required NR_API_KEY and optionally
NR_ACCOUNT_ID if using Insights events, via environment variables.
EOF

  export NR_STATSD_CFG=/tmp/nri-statsd.toml
  /bin/cat <<EOM >${NR_STATSD_CFG}

backends='newrelic'
metrics-addr="${NR_STATSD_METRICS_ADDR}"

[newrelic]
flush-type = "metrics"
transport = "default"
address = "${NR_ENDPOINT_ADDR}"
address-metrics = "${NR_ENDPOINT_METRICS_ADDR}"
api-key = "${NR_API_KEY}"
EOM
fi

exec ./run-statsd.sh
