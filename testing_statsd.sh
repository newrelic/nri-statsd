#!/bin/bash

echo "prod.test.counter:1|c" | nc -v -w 1 -u localhost 8125
echo "prod.test.counter:22|c" | nc -v -w 1 -u localhost 8125
echo "prod.test.counter:1|c|@0.1" | nc -v -w 1 -u localhost 8125

echo "prod.test.num:32|g" | nc -v -w 1 -u localhost 8125
echo "prod.test.num2:13|g" | nc -v -w 1 -u localhost 8125
