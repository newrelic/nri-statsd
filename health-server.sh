#!/bin/sh

# Simple health check server script
# This script starts a netcat listener on the specified port
# and responds with a 200 OK to any HTTP request

PORT=${1:-8126}

echo "Starting health check server on port $PORT"

while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p $PORT
done
