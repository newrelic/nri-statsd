#!/bin/bash

# Simple script to test the health check endpoints
# This script uses netcat to send simple HTTP requests to the health check endpoints

PORT=${1:-8126}
HOST=${2:-localhost}
PATH=${3:-/}

echo "Testing endpoint $PATH on $HOST:$PORT..."

# Send a simple HTTP GET request to the specified endpoint
{
  echo -e "GET $PATH HTTP/1.1\r\nHost: $HOST\r\nConnection: close\r\n\r\n"
} | nc $HOST $PORT

echo "Done."

# No need to test other endpoints, as we only have one simple endpoint now
if [ "$PATH" = "/" ]; then
  echo ""
  echo "Note: The health check endpoint returns:"
  echo "- 200 OK if gostatsd is running"
  echo "- 503 Service Unavailable if gostatsd is not running"
fi
