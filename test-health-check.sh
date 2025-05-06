#!/bin/bash

# Test script for nri-statsd health check
# This script tests both the custom health check script and the built-in HTTP health check server

echo "Testing nri-statsd health check..."

# Function to test HTTP endpoint
test_endpoint() {
  local port=$1
  local endpoint=${2:-"/"}
  local expected_status=${3:-200}

  echo "Testing HTTP endpoint on port $port, endpoint $endpoint, expecting status $expected_status"

  # Use curl to test the endpoint
  response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port$endpoint)

  if [ "$response" -eq "$expected_status" ]; then
    echo "✅ Success: Got expected status code $response"
    return 0
  else
    echo "❌ Error: Expected status code $expected_status, got $response"
    return 1
  fi
}

# Function to test TCP connection
test_tcp_connection() {
  local port=$1

  echo "Testing TCP connection on port $port"

  # Use nc to test TCP connection
  if nc -z localhost $port; then
    echo "✅ Success: TCP connection to port $port succeeded"
    return 0
  else
    echo "❌ Error: TCP connection to port $port failed"
    return 1
  fi
}

# Test the root path (for AWS LoadBalancer health checks)
echo "Testing root path (for AWS LoadBalancer health checks)..."
test_endpoint 8126 "/"

# Test the health check path (for detailed status)
echo "Testing health check path (for detailed status)..."
test_endpoint 8126 "/health"

# Test the status path (alternative to health)
echo "Testing status path (alternative to health)..."
test_endpoint 8126 "/status"

# Test TCP connection (for AWS LoadBalancer health checks)
echo "Testing TCP connection (for AWS LoadBalancer health checks)..."
test_tcp_connection 8126

# Print a note about the health check
echo ""
echo "Note: The health check endpoint should return:"
echo "- 200 OK if gostatsd is running"
echo "- 503 Service Unavailable if gostatsd is not running"

echo "Health check tests completed."
