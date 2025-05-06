#!/bin/sh

# Simple HTTP proxy script
# This script listens on the specified port and forwards requests to the target port
# If the target port doesn't respond, it returns a 200 OK response with a simple JSON payload

LISTEN_PORT=${1:-8126}
TARGET_PORT=${2:-8127}

echo "Starting HTTP proxy on port $LISTEN_PORT, forwarding to port $TARGET_PORT"

while true; do
  # Accept connection using netcat
  {
    # Read the HTTP request
    read -r request
    
    # Try to forward the request to the target port
    RESPONSE=$(echo -e "$request\r\n" | nc -w 1 localhost $TARGET_PORT 2>/dev/null)
    
    # Check if we got a response
    if [ -n "$RESPONSE" ]; then
      # Forward the response
      echo "$RESPONSE"
    else
      # Return a 200 OK response with a simple JSON payload
      echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 15\r\n\r\n{\"status\":\"ok\"}"
    fi
  } | nc -l -p $LISTEN_PORT
  
  # Short sleep to prevent CPU spinning if netcat exits unexpectedly
  sleep 0.1
done
