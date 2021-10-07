## Description
[Vagrant](https://www.vagrantup.com/) virtual machine with statsd daemon and nri-statsd integration running to help troubleshooting.

## Run
```bash
NR_ACCOUNT_ID=YOUR_ACCOUNT_ID NR_API_KEY=YOUR_API_KEY [NR_EU_REGION=true] vagrant up
# just provision
NR_ACCOUNT_ID=YOUR_ACCOUNT_ID NR_API_KEY=YOUR_API_KEY [NR_EU_REGION=true] vagrant provision
# just run tests to send data
NR_ACCOUNT_ID=YOUR_ACCOUNT_ID NR_API_KEY=YOUR_API_KEY [NR_EU_REGION=true] vagrant provision  --provision-with run-test
```

