#!/bin/bash
set -e

# Configuration
MODEL_REGISTRY="jozu.ml"
MODEL_USERNAME="siddhesh-bangar"  # Replace with your Jozu Hub username
MODEL_NAME="text-classification-model"
MODEL_TAG="latest"

# Set the image names
MODEL_IMAGE="${MODEL_REGISTRY}/${MODEL_USERNAME}/${MODEL_NAME}:${MODEL_TAG}"
WEB_UI_IMAGE="kitops-web-ui:latest"

echo "=== Deploying KitOps + Jozu Hub model to Kubernetes ==="
echo ""

# Step 1: Pull the model from Jozu Hub
echo "Step 1: Pulling model from Jozu Hub..."
# Check if KitOps CLI is installed
if ! command -v kit &> /dev/null; then
    echo "KitOps CLI is not installed. Please install it first:"
    echo "curl -sSL https://get.kitops.org | sh"
    exit 1
fi

# Try to pull the model (but don't exit if it fails)
kit pull ${MODEL_IMAGE} || echo "Warning: Could not pull model, but continuing with deployment"

# Step 2: Build and push the web UI image
echo ""
echo "Step 2: Building web UI image..."
docker build -t ${WEB_UI_IMAGE} ../web-ui
echo "Web UI image built successfully"

# Step 3: Replace image placeholders in Kubernetes manifests
echo ""
echo "Step 3: Updating Kubernetes manifests with image names..."
sed -i "s|jozu.ml/siddhesh-bangar/text-classification-model:latest|${MODEL_IMAGE}|g" model-deployment.yaml
sed -i "s|\${WEB_UI_IMAGE}|${WEB_UI_IMAGE}|g" web-ui-deployment.yaml
echo "Manifests updated successfully"

# Step 4: Apply Kubernetes manifests
echo ""
echo "Step 4: Applying Kubernetes manifests..."
kubectl apply -f model-deployment.yaml
kubectl apply -f web-ui-deployment.yaml
echo "Kubernetes resources created successfully"

# Step 5: Wait for deployments to be ready
echo ""
echo "Step 5: Waiting for deployments to be ready..."
kubectl rollout status deployment/model-service
kubectl rollout status deployment/web-ui
echo "Deployments are ready"

# Step 6: Get access information
echo ""
echo "Step 6: Getting access information..."
echo "To access the application, you need to find the external IP or hostname of your ingress:"
echo "kubectl get ingress model-ingress"
echo ""
echo "If you're using Minikube, you can access the application with:"
echo "minikube service web-ui --url"
echo ""
echo "=== Deployment completed successfully! ==="