[![Community Project header](https://github.com/newrelic/open-source-office/raw/master/examples/categories/images/Community_Project.png)](https://github.com/newrelic/open-source-office/blob/master/examples/categories/index.md#community-project)

# StatsD Integration for New Relic Infrastructure ![Publish container image](https://github.com/newrelic/nri-statsd/workflows/Publish%20container%20image/badge.svg)

>StatsD integration lets you easily get StatsD - format data into New Relic. You can also add any arbitrary tags (key-value pairs) to your data.
Once your metrics are in New Relic, you can query your data and create custom charts and dashboards.

## Requirements

>The StatsD integration uses our Metric API and our Event API to ingest data. To send data to both APIs you need a New Relic Insert API key. You can generate one at this URL (use your account ID):
 
https://insights.newrelic.com/accounts/YOUR_ACCOUNT_ID/manage/api_keys

## Installation

> To install the StatsD integration, run the container with this command, inserting your [account ID](https://docs.newrelic.com/docs/accounts/install-new-relic/account-setup/account-id) and API key:
```bash
docker run \
  -d --restart unless-stopped \
  --name newrelic-statsd \
  -h $(hostname) \
  -e NR_ACCOUNT_ID=YOUR_ACCOUNT_ID \
  -e NR_API_KEY=YOUR_INSERT_API_KEY \
  -p 8125:8125/udp \
  newrelic/nri-statsd:latest
```

If your account is in the EU data center region, set the NR_EU_REGION environment variable to true. For example, you can add this to the above command: 

```bash
-e NR_EU_REGION=true \
```

## Find and use data

You can send some data using the following example:
```bash 
echo "prod.test.num:32|g" | nc -v -w 1 -u localhost 8125
```

To query your data, you'd use any New Relic [query option](https://docs.newrelic.com/docs/using-new-relic/data/understand-data/query-new-relic-data). For example, you might run a [NRQL](https://docs.newrelic.com/docs/query-data/nrql-new-relic-query-language/getting-started/introduction-nrql) query like:

```bash
SELECT latest(prod.test.num) FROM Metric WHERE metricName = 'prod.test.num'
```

## Building

You can build your own custom nri-statsd docker image by using the following command:

```bash
docker build -t nri-statsd:$IMAGE_VERSION \
.
```

## Configuration

When you use the standard [instalation method](#Installation), a statsd config file will be automatically generated
with the default recommended values. However if you want to customize your statsd configuration you can do this by
overwriting the default config file.

Example:
nri-statsd.toml
```bash
backends='newrelic'
flush-interval='10s'

[newrelic]
# flush types supported: metrics,  insights, infra
flush-type = 'metrics'
transport = 'default'
address-metrics = 'https://metric-api.newrelic.com/metric/v1'
api-key = 'NEW_RELIC_API_KEY'
```

Mount the config file to the statsd container:
```bash
docker run \
  ...
  -v ${PWD}/nri-statsd.toml:/etc/opt/newrelic/nri-statsd.toml \
  ...
  newrelic/nri-statsd:latest
```

## Configuration parameters

| Parameter               | Type             |      Description     |
|-------------------------|------------------|----------------------|
| expiry-interval         | string           |If a metric is not updated for this amount of time,<br>we stop reporting that metric. Default is 5m. If you<br>want to send the metrics only if the value was updated<br>between the flush intervals, configure this to 1ms.<br>To never expire metrics, set it to 0. |
| percent-threshold       | list of integers | Specifies the percentiles used for metrics aggregation. Default: 90.
| metrics-addr            | string           | Indicates address on which to listen for metrics. Default: :8125.

## Metric format

The integration receives metrics using the [StatsD](https://github.com/statsd/statsd) protocol. Optionally, the sample rate and tags can also be sent.

Here's the metric data format we use:

```bash
<metric_name>:<value>|<type>|@<sample_rate>|#<tags>
```

| Field name      | Type    |	Description
|-----------------|---------|----------------------|
| \<metric_name>  | string  | Required. Name of the metric.
| \<value>        | string  | Required. The metric type:<br>c = Counter<br>g = Gauge<br>ms = Timer
| @\<sample_rate> | float	| Optional for simple counters or timer counters. When many metrics must be sent,<br>you can use sampling to reduce network traffic. The downside is a reduction in<br>the resolution of the data.<br>An example of how this would work for values lower than 1:<br>Setting this to 0.1 results in the counter sending data 1 out of every 10 times it is measured.
|#\<tags>         | string  | Optional. Tags attached to your metrics are converted into attributes (key-value pairs).<br>For more on tagging options, see [Add tags (attributes)](#Add-tags-(attributes)) section.


## Add tags (attributes)
You can add tags to your data, which we save as attributes (key-value pairs). There are two options for adding tags:

### 1. When defining the metric format, you can add tags using this format:

```bash
prod.test.num:32|g|#environment:production,region:us
```
In this example, the tags are a comma-separated list of tags. Tags format is: simple or key:value.


Here's an example NRQL query that includes a custom tag:

```bash
SELECT count(*) FROM Metric WHERE environment = 'production'
```

### 2. When running nri-statsd add default tags that apply to all metrics.<br>
They are fixed, apply to all the metrics and don't change over time. This can be done by using `TAGS` environment variable
```bash
docker run \
  ...
  -e TAGS="environment:production region:us" \ 
  ...
  newrelic/nri-statsd:latest
```

## Deploy in Kubernetes

Below are examples of Kubernetes manifests to deploy StatsD in a Kubernetes environment and create a StatsD service named newrelic-statsd. You need to insert your account ID and your license key.

deployment.yml:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: newrelic-statsd
  namespace: tooling
  labels:
    app: newrelic-statsd
spec:
  selector:
    matchLabels:
      app: newrelic-statsd
  replicas: 2
  revisionHistoryLimit: 2
  template:
    metadata:
      labels:
        app: newrelic-statsd
    spec:
      containers:
      - name: newrelic-statsd
        image: newrelic/nri-statsd:latest
        env:
        - name: NR_ACCOUNT_ID
          value: "NEW_RELIC_ACCOUNT_ID"
        - name: NR_API_KEY
          value: "NEW_RELIC_LICENSE_KEY"
```

service.yml:
```bash
apiVersion: v1
kind: Service
metadata:
  name: newrelic-statsd
  namespace: tooling
  labels:
    app: newrelic-statsd
  annotations:
spec:
  type: ClusterIP
  ports:
  - name: newrelic-statsd
    port: 80
    targetPort: 8125
    protocol: UDP
  selector:
    app: newrelic-statsd
```

## Support

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub. You can find this project's topic/threads here:

>https://discuss.newrelic.com/tags/c/support-products-agents/new-relic-infrastructure/on-host-integrations

## Contributing
Full details about how to contribute to
Contributions to improve StatsD Integration are encouraged! Keep in mind when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.
To execute our corporate CLA, which is required if your contribution is on behalf of a company, or if you have any questions, please drop us an email at open-source@newrelic.com.

## License
nri-statsd is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
>nri-statsd also uses source code from third party libraries. Full details on which libraries are used and the terms under which they are licensed can be found in the third party notices document.]
