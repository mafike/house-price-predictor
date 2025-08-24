#!/bin/bash

# Load Test Script using curl
# Usage: ./load-test.sh [duration_in_minutes] [concurrent_requests]

# Set default values
DURATION_MINUTES=${1:-3}
CONCURRENT_REQUESTS=${2:-200}

echo "Starting load test for $DURATION_MINUTES minutes with $CONCURRENT_REQUESTS concurrent requests"
echo "Target: http://localhost:30100/predict"
echo "Press Ctrl+C to stop early"
echo "----------------------------------------"

# Calculate end time
END_TIME=$(( $(date +%s) + (DURATION_MINUTES * 60) ))
REQUEST_COUNT=0
PIDS=()

# Function to clean up background processes
cleanup() {
    echo ""
    echo "Stopping load test..."
    for pid in "${PIDS[@]}"; do
        kill $pid 2>/dev/null
    done
    wait
    echo "Load test stopped. Total requests sent: $REQUEST_COUNT"
    exit 0
}

# Set up signal handler for Ctrl+C
trap cleanup SIGINT SIGTERM

# Main loop
while [ $(date +%s) -lt $END_TIME ]; do
    # Clean up completed background processes
    for i in "${!PIDS[@]}"; do
        if ! kill -0 "${PIDS[i]}" 2>/dev/null; then
            unset "PIDS[i]"
            ((REQUEST_COUNT++))
        fi
    done
    PIDS=("${PIDS[@]}") # Reindex array

    # Start new requests if we're under the concurrency limit
    while [ ${#PIDS[@]} -lt $CONCURRENT_REQUESTS ] && [ $(date +%s) -lt $END_TIME ]; do
        # Send the curl request in background
        curl -X POST http://localhost:30100/predict \
            -H "Content-Type: application/json" \
            -d @predict.json \
            --silent \
            --output /dev/null \
            --max-time 30 \
            --connect-timeout 5 &
        
        PIDS+=($!)
    done

    # Small sleep to prevent CPU overload
    sleep 0.1
done

# Wait for any remaining background processes
echo "Waiting for remaining requests to complete..."
for pid in "${PIDS[@]}"; do
    wait $pid 2>/dev/null && ((REQUEST_COUNT++))
done

echo "----------------------------------------"
echo "Load test completed!"
echo "Total time: $DURATION_MINUTES minutes"
echo "Total requests sent: $REQUEST_COUNT"
echo "Approximate requests/sec: $(($REQUEST_COUNT / (DURATION_MINUTES * 60)))"
