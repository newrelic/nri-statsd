#!/bin/sh

# Simple health check script for nri-statsd
# This script provides a simple HTTP server that returns 200 OK if gostatsd is running

PORT=${1:-8126}

# Function to check if gostatsd is running
check_gostatsd_running() {
  if pgrep -f "/bin/gostatsd" > /dev/null; then
    return 0  # Process is running
  else
    return 1  # Process is not running
  fi
}

# Check if the port is already in use
if nc -z localhost $PORT 2>/dev/null; then
  echo "Port $PORT is already in use, trying a different port"
  # Try to find an available port
  for test_port in 8127 8128 8129 8130; do
    if ! nc -z localhost $test_port 2>/dev/null; then
      PORT=$test_port
      echo "Using port $PORT for health check server"
      break
    fi
  done
fi

# Main HTTP server loop
echo "Starting simple health check server on port $PORT"

while true; do
  # Accept connection using netcat
  {
    # Read the HTTP request (we don't actually need to parse it)
    read -r request

    # Check if gostatsd is running
    if check_gostatsd_running; then
      # gostatsd is running, return 200 OK
      response_body="{\"status\":\"ok\"}"
      response_length=${#response_body}
      echo "HTTP/1.1 200 OK"
      echo "Content-Type: application/json"
      echo "Content-Length: $response_length"
      echo ""
      echo "$response_body"
    else
      # gostatsd is not running, return 503 Service Unavailable
      response_body="{\"status\":\"error\",\"message\":\"gostatsd is not running\"}"
      response_length=${#response_body}
      echo "HTTP/1.1 503 Service Unavailable"
      echo "Content-Type: application/json"
      echo "Content-Length: $response_length"
      echo ""
      echo "$response_body"
    fi
  } | nc -l -p $PORT

  # Short sleep to prevent CPU spinning if netcat exits unexpectedly
  sleep 0.1
done
