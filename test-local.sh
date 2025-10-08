#!/bin/bash
set -e

echo "=== Testing KitOps + Jozu Hub Model Deployment Locally ==="
echo ""

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Check if Docker is running
echo "Step 1: Checking if Docker is running..."
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi
echo "Docker is running"

# Step 2: Build and start the services
echo ""
echo "Step 2: Building and starting services with Docker Compose..."
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" down 2>/dev/null || true
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up -d --build
echo "Services started successfully"

# Step 3: Wait for services to be ready
echo ""
echo "Step 3: Waiting for services to be ready..."
echo "Waiting for model-service to be healthy..."

# Set a timeout for health check
TIMEOUT=60
START_TIME=$(date +%s)
HEALTH_CHECK_SUCCESSFUL=false

while [ $(($(date +%s) - START_TIME)) -lt $TIMEOUT ]; do
  if curl -s http://localhost:8000/health > /dev/null; then
    HEALTH_CHECK_SUCCESSFUL=true
    break
  fi
  echo -n "."
  sleep 2
done

echo ""
if [ "$HEALTH_CHECK_SUCCESSFUL" = true ]; then
  echo "Model service is ready"
else
  echo "Timed out waiting for model service to be healthy"
  echo "Checking model service logs:"
  docker logs kitops-jozu-workflow-model-service-1
  echo ""
  echo "You can still try to access the services manually:"
  echo "Model API: http://localhost:8000"
  echo "Web UI: http://localhost:8080"
  exit 1
fi

# Step 4: Test the model API
echo ""
echo "Step 4: Testing the model API..."
echo "Sending a test request to the model API..."
curl -s -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product, it is amazing!"}' | jq . || echo "Failed to get response from API"
echo ""
echo "API test completed"

# Step 5: Open the web UI
echo ""
echo "Step 5: Opening the web UI..."
echo "The web UI is available at: http://localhost:8080"
echo "You can open it in your browser to interact with the model"

# Print usage instructions
echo ""
echo "=== Local Deployment Information ==="
echo "Model API: http://localhost:8000"
echo "Web UI: http://localhost:8080"
echo ""
echo "To stop the services, run: docker-compose -f \"$SCRIPT_DIR/docker-compose.yml\" down"
echo ""
echo "=== Test completed successfully! ==="
